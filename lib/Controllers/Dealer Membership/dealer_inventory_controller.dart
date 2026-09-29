import 'package:get/get.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_paged_list.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_inventory_car_model.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Widgets/toast_widget.dart';

class DealerInventoryController extends GetxController {
  static DealerInventoryController get to =>
      Get.isRegistered<DealerInventoryController>()
          ? Get.find<DealerInventoryController>()
          : Get.put(DealerInventoryController(), permanent: true);

  final membership = DealerMembershipController.to;

  late final dealerCars = _list(DealerInventoryCarModel.dealerOwned);
  late final customerCars = _list(DealerInventoryCarModel.customerOwned);
  final isSaving = false.obs;

  DealerPagedList<DealerInventoryCarModel> _list(String ownership) =>
      DealerPagedList(
        (page) async => DealerPagedList.parse(
          await DealerMembershipApi.get(
            AppUrls.dealerInventoryList(
              ownership: ownership,
              page: page,
              limit: 20,
            ),
          ),
          DealerInventoryCarModel.fromJson,
        ),
      );

  DealerPagedList<DealerInventoryCarModel> listFor(String ownership) =>
      ownership == DealerInventoryCarModel.customerOwned
          ? customerCars
          : dealerCars;

  Future<void> loadCars(String ownership, {bool reset = false}) =>
      listFor(ownership).load(reset: reset);

  Future<DealerInventoryCarModel?> getCar(String id) async {
    try {
      final data = await DealerMembershipApi.get(
        AppUrls.dealerInventoryCar(id),
      );
      return DealerInventoryCarModel.fromJson(Map<String, dynamic>.from(data));
    } on DealerApiException catch (e) {
      membership.handleError(e, title: 'Could not open the car');
      return null;
    }
  }

  Future<DealerRcPrefillModel?> fetchDetails(String registrationNumber) async {
    try {
      final data = await DealerMembershipApi.post(
        AppUrls.dealerInventoryFetchDetails,
        {'registrationNumber': registrationNumber},
      );
      return DealerRcPrefillModel.fromJson(Map<String, dynamic>.from(data));
    } on DealerApiException catch (e) {
      membership.handleError(e, title: 'Could not fetch details');
      return null;
    }
  }

  Future<String> uploadImage(String filePath) async {
    final data = Map<String, dynamic>.from(
      await DealerMembershipApi.upload(
        AppUrls.dealerInventoryUploadImage,
        field: 'image',
        filePaths: [filePath],
      ),
    );
    return data['url'].toString();
  }

  Future<bool> saveCar(Map<String, dynamic> body, {String? id}) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    try {
      final data =
          id == null
              ? await DealerMembershipApi.post(AppUrls.dealerInventory, body)
              : await DealerMembershipApi.put(
                AppUrls.dealerInventoryCar(id),
                body,
              );
      final car = DealerInventoryCarModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      _upsert(car);
      membership.loadHome(silent: true);
      _toast(id == null ? 'Car listed' : 'Changes saved', car.title);
      return true;
    } on DealerApiException catch (e) {
      membership.handleError(e, title: 'Could not save the car');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> setStatus(DealerInventoryCarModel car, String status) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    try {
      final data = await DealerMembershipApi.put(
        AppUrls.dealerInventoryCarStatus(car.id),
        {'status': status},
      );
      final updated = DealerInventoryCarModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      final list = listFor(car.ownership);
      if (updated.status == 'SOLD' || updated.status == 'ARCHIVED') {
        list.items.removeWhere((c) => c.id == car.id);
      } else {
        _upsert(updated);
      }
      membership.loadHome(silent: true);
      return true;
    } on DealerApiException catch (e) {
      membership.handleError(e, title: 'Could not update the car');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  void _upsert(DealerInventoryCarModel car) {
    final list = listFor(car.ownership);
    final index = list.items.indexWhere((c) => c.id == car.id);
    if (index == -1) {
      list.items.insert(0, car);
    } else {
      list.items[index] = car;
    }
  }

  void _toast(String title, String subtitle) {
    final context = Get.context;
    if (context == null) return;
    ToastWidget.show(
      context: context,
      title: title,
      subtitle: subtitle,
      type: ToastType.success,
    );
  }
}
