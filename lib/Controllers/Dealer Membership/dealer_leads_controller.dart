import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_membership_controller.dart';
import 'package:otobix/Controllers/Dealer%20Membership/dealer_paged_list.dart';
import 'package:otobix/Models/Dealer%20Membership/dealer_lead_model.dart';
import 'package:otobix/Network/dealer_membership_api.dart';
import 'package:otobix/Utils/app_urls.dart';
import 'package:otobix/Widgets/toast_widget.dart';

class DealerLeadsController extends GetxController {
  static DealerLeadsController get to =>
      Get.isRegistered<DealerLeadsController>()
          ? Get.find<DealerLeadsController>()
          : Get.put(DealerLeadsController(), permanent: true);

  final membership = DealerMembershipController.to;
  final isSaving = false.obs;

  late final allLeads = leadsFor();

  DealerPagedList<DealerLeadModel> leadsFor({String carId = ''}) =>
      DealerPagedList(
        (page) async => DealerPagedList.parse(
          await DealerMembershipApi.get(
            AppUrls.dealerLeads({
              if (carId.isNotEmpty) 'carId': carId,
              'page': '$page',
              'limit': '20',
            }),
          ),
          DealerLeadModel.fromJson,
        ),
      );

  Future<DealerLeadModel?> addLead(Map<String, dynamic> body) => _save(
    () => DealerMembershipApi.post(AppUrls.dealerLeadCreate, body),
    success: 'Lead added',
  );

  Future<DealerLeadModel?> updateStatus(
    String id,
    String status,
    Map<String, dynamic> details,
  ) => _save(
    () => DealerMembershipApi.put(AppUrls.dealerLeadStatus(id), {
      'status': status,
      'details': details,
    }),
    success: _statusSaved(status, details),
  );

  // The server reminds the dealer when a showroom visit still to come is due.
  static String _statusSaved(String status, Map<String, dynamic> details) {
    final at = DateTime.tryParse('${details['visitAt'] ?? ''}')?.toLocal();
    final remind =
        status == 'SCHEDULED_SHOWROOM_VISIT' &&
        const ['Scheduled', 'Deferred'].contains(details['visitStatus']) &&
        at != null &&
        at.isAfter(DateTime.now());
    return remind
        ? 'Status updated · reminder at ${DateFormat('d MMM, h:mm a').format(at)}'
        : 'Status updated';
  }

  Future<DealerLeadModel?> _save(
    Future<dynamic> Function() call, {
    required String success,
  }) async {
    if (isSaving.value) return null;
    isSaving.value = true;
    try {
      final lead = DealerLeadModel.fromJson(
        Map<String, dynamic>.from(await call()),
      );
      _toast(success);
      membership.loadHome(silent: true);
      return lead;
    } on DealerApiException catch (e) {
      membership.handleError(e, title: 'Could not save the lead');
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  void _toast(String title) {
    final context = Get.context;
    if (context == null) return;
    ToastWidget.show(context: context, title: title, type: ToastType.success);
  }
}
