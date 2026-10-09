import 'package:otobix/Utils/global_functions.dart';

String _str(dynamic v) => GlobalFunctions.parse<String>(v) ?? '';
int _int(dynamic v) => GlobalFunctions.parse<int>(v) ?? 0;

class DealerVehicleFactsModel {
  final String registrationNumber;
  final String makerDescription;
  final String makerModel;
  final String make;
  final String model;
  final String variant;
  final int mfgYear;
  final int regnYear;
  final String registrationDate;
  final String colour;
  final String fuelType;
  final String bodyType;
  final String normsType;
  final String registrationType;
  final String rcStatus;
  final String rto;
  final String registrationState;
  final int ownerSerialNo;
  final String fitnessUpto;
  final String taxUpto;
  final String insuranceUpto;
  final String insuranceProvider;
  final bool financed;
  final String financier;
  final String pucUpto;
  final String blacklistStatus;
  final String nocStatus;
  final String ownerMasked;
  final String chassisMasked;
  final String engineMasked;

  DealerVehicleFactsModel.fromJson(Map<String, dynamic> j)
    : registrationNumber = _str(j['registrationNumber']),
      makerDescription = _str(j['makerDescription']),
      makerModel = _str(j['makerModel']),
      make = _str(j['make']),
      model = _str(j['model']),
      variant = _str(j['variant']),
      mfgYear = _int(j['mfgYear']),
      regnYear = _int(j['regnYear']),
      registrationDate = _str(j['registrationDate']),
      colour = _str(j['colour']),
      fuelType = _str(j['fuelType']),
      bodyType = _str(j['bodyType']),
      normsType = _str(j['normsType']),
      registrationType = _str(j['registrationType']),
      rcStatus = _str(j['rcStatus']),
      rto = _str(j['rto']),
      registrationState = _str(j['registrationState']),
      ownerSerialNo = _int(j['ownerSerialNo']),
      fitnessUpto = _str(j['fitnessUpto']),
      taxUpto = _str(j['taxUpto']),
      insuranceUpto = _str(j['insuranceUpto']),
      insuranceProvider = _str(j['insuranceProvider']),
      financed = j['financed'] == true,
      financier = _str(j['financier']),
      pucUpto = _str(j['pucUpto']),
      blacklistStatus = _str(j['blacklistStatus']),
      nocStatus = _str(j['nocStatus']),
      ownerMasked = _str(j['ownerMasked']),
      chassisMasked = _str(j['chassisMasked']),
      engineMasked = _str(j['engineMasked']);
}

class DealerChallanModel {
  final String challanNumber;
  final String offence;
  final String place;
  final String date;
  final int amount;
  final String status;
  final bool isPending;

  DealerChallanModel.fromJson(Map<String, dynamic> j)
    : challanNumber = _str(j['challanNumber']),
      offence = _str(j['offence']),
      place = _str(j['place']),
      date = _str(j['date']),
      amount = _int(j['amount']),
      status = _str(j['status']),
      isPending = j['isPending'] == true;
}

class DealerRcCheckModel {
  final DealerVehicleFactsModel vehicle;
  final List<DealerChallanModel>? challans;
  final int pendingChallans;
  final int pendingTotal;
  final String challanError;
  final String ownerMobile;
  final String mobileError;
  final DateTime? consentRecordedAt;
  final int pointsCharged;
  final int availablePoints;

  DealerRcCheckModel.fromJson(Map<String, dynamic> j)
    : vehicle = DealerVehicleFactsModel.fromJson(
        Map<String, dynamic>.from(j['vehicle'] ?? {}),
      ),
      challans =
          j['challans'] is Map
              ? (j['challans']['items'] as List? ?? [])
                  .map(
                    (e) => DealerChallanModel.fromJson(
                      Map<String, dynamic>.from(e),
                    ),
                  )
                  .toList()
              : null,
      pendingChallans = _int(j['challans']?['pendingCount']),
      pendingTotal = _int(j['challans']?['pendingTotal']),
      challanError = _str(j['challanError']),
      ownerMobile = _str(j['ownerMobile']),
      mobileError = _str(j['mobileError']),
      consentRecordedAt = GlobalFunctions.parse<DateTime>(
        j['consentRecordedAt'],
      ),
      pointsCharged = _int(j['pointsCharged']),
      availablePoints = _int(j['availablePoints']);
}
