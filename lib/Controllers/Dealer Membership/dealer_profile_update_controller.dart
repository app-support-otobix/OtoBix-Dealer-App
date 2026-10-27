import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_membership_model.dart';
import 'package:otobix/Models/place_model.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Widgets/toast_widget.dart';

/// The dealer's profile: dealer type, city, state, GSTIN, trade distance and
/// the showroom location. Saving updates the membership card too.
class DealerProfileUpdateController extends GetxController {
  static DealerProfileUpdateController get to =>
      Get.isRegistered<DealerProfileUpdateController>()
          ? Get.find<DealerProfileUpdateController>()
          : Get.put(DealerProfileUpdateController(), permanent: true);

  final isSubmitting = false.obs;
  final isLocating = false.obs;

  Rxn<DealerMembershipModel> get _membership =>
      DealerMembershipController.to.membership;

  Future<bool> updateProfile({
    required String dealerType,
    required String city,
    required String state,
    required String gstin,
    required int tradeRadiusKm,
  }) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    try {
      final data = await DealerMembershipApi.post(AppUrls.dealerProfileUpdate, {
        'dealerType': dealerType,
        'city': city,
        'state': state,
        'gstin': gstin,
        'tradeRadiusKm': tradeRadiusKm,
      });
      _membership.value = DealerMembershipModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      _toast(
        'Details saved',
        'Your dealer details are updated.',
        ToastType.success,
      );
      return true;
    } on DealerApiException catch (e) {
      _toast('Could not save your details', e.message, ToastType.error);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Saves the showroom location from a searched address ([place], which has a
  /// position) or else the phone's GPS (the dealer is asked to do this at the
  /// showroom); other dealers' cars then show their distance from it. Only the
  /// distance ever reaches other dealers.
  Future<bool> setShowroomLocation({PlaceDetailsModel? place}) async {
    if (isLocating.value) return false;
    isLocating.value = true;
    try {
      final gps = place == null ? await _currentPosition() : null;
      final data =
          await DealerMembershipApi.put(AppUrls.dealerShowroomLocation, {
            'latitude': place?.latitude ?? gps!.latitude,
            'longitude': place?.longitude ?? gps!.longitude,
          });
      _membership.value = DealerMembershipModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      _toast(
        'Showroom location saved',
        "Other dealers' cars now show how far they are from you.",
        ToastType.success,
      );
      return true;
    } on _LocationUnavailable catch (e) {
      _toast('Location not available', e.message, ToastType.error);
      return false;
    } on DealerApiException catch (e) {
      _toast('Could not save the location', e.message, ToastType.error);
      return false;
    } finally {
      isLocating.value = false;
    }
  }

  /// The phone's GPS position (e.g. where a customer's car is), or null with a
  /// toast saying why (GPS off, permission refused, no fix).
  Future<Position?> phonePosition() async {
    if (isLocating.value) return null;
    isLocating.value = true;
    try {
      return await _currentPosition();
    } on _LocationUnavailable catch (e) {
      _toast('Location not available', e.message, ToastType.error);
      return null;
    } finally {
      isLocating.value = false;
    }
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const _LocationUnavailable(
        'Turn on location (GPS) on your phone and try again.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw const _LocationUnavailable(
        'Allow location for OtoBix in Settings, then try again.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const _LocationUnavailable(
        'Allow location access to set your showroom location.',
      );
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      throw const _LocationUnavailable(
        'Could not get a GPS fix. Step outside or near a window and try again.',
      );
    }
  }

  void _toast(String title, String subtitle, ToastType type) {
    final context = Get.context;
    if (context == null) return;
    ToastWidget.show(
      context: context,
      title: title,
      subtitle: subtitle,
      type: type,
    );
  }
}

/// Why the phone could not give a showroom location, in the dealer's words.
class _LocationUnavailable implements Exception {
  final String message;
  const _LocationUnavailable(this.message);
}
