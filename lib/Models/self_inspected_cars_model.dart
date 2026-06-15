import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:otobix/helpers/model_helpers.dart';

class SelfInspectedCarModel {
  // ==================== RC Details (Auto Fetch) ====================
  final String? id;
  final String registrationNumber;
  final String make;
  final String model;
  final String variant;
  final String roadTaxValidity;
  final DateTime? taxValidTill;
  final DateTime? registrationDate;
  final DateTime? fitnessValidity;
  final String engineNumber;
  final String chassisNumber;
  final DateTime? manufacturingDate;
  final String fuelType;
  final int cubicCapacity;
  final String registrationState;
  final String registeredRTO;
  final int ownershipSerialNo;
  final String registeredOwner;
  final String registeredAddressAsPerRC;
  final String hypothecationDetails;
  final String financierName;
  final DateTime? insuranceValidity;
  final String rcStatus;
  final String blacklistStatus;
  final DateTime? pucValidityDate;
  final String pucNumber;

  // ==================== Images (Manual Entry) ====================
  final String frontMainImage;
  final String rhsFullImage;
  final String rearMainImage;
  final String bootFloorImage;
  final String lhsMainImage;
  final String engineBayImage;
  final String dashboardImage;

  // ==================== Vehicle Condition (Manual Entry) ====================
  final int odometer;
  final String accidentalStatus;
  final String clutch;
  final String suspension;
  final String steering;
  final String brake;
  final String ac;

  // ==================== Additional Details ====================
  final DateTime? expectedDateOfCarHandover;
  final RxInt expectedPrice;

  // ==================== System Fields ====================
  final String inspectionId;
  final String userId;
  final String auctionStatus;
  final String additionalNotes;
  final int priceDiscovery;
  final String priceDiscoveryBy;
  final RxInt highestOffer;
  final RxString highestOfferBy;
  final DateTime? auctionStartTime;
  final DateTime? auctionEndTime;
  final RxDouble fixedMargin;
  final RxDouble variableMargin;

  SelfInspectedCarModel({
    this.id,
    required this.inspectionId,
    required this.registrationNumber,
    required this.make,
    required this.model,
    required this.variant,
    required this.roadTaxValidity,
    this.taxValidTill,
    this.registrationDate,
    this.fitnessValidity,
    required this.engineNumber,
    required this.chassisNumber,
    this.manufacturingDate,
    required this.fuelType,
    required this.cubicCapacity,
    required this.registrationState,
    required this.registeredRTO,
    required this.ownershipSerialNo,
    required this.registeredOwner,
    required this.registeredAddressAsPerRC,
    required this.hypothecationDetails,
    required this.financierName,
    this.insuranceValidity,
    required this.rcStatus,
    required this.blacklistStatus,
    this.pucValidityDate,
    required this.pucNumber,
    required this.frontMainImage,
    required this.rhsFullImage,
    required this.rearMainImage,
    required this.bootFloorImage,
    required this.lhsMainImage,
    required this.engineBayImage,
    required this.dashboardImage,
    required this.odometer,
    required this.accidentalStatus,
    required this.clutch,
    required this.suspension,
    required this.steering,
    required this.brake,
    required this.ac,
    this.expectedDateOfCarHandover,
    required this.expectedPrice,
    required this.userId,
    required this.auctionStatus,
    required this.additionalNotes,
    required this.priceDiscovery,
    required this.priceDiscoveryBy,
    required this.highestOffer,
    required this.highestOfferBy,
    this.auctionStartTime,
    this.auctionEndTime,
    required this.fixedMargin,
    required this.variableMargin,
  });

  // ==================== FROM JSON ====================
  factory SelfInspectedCarModel.fromJson(Map<String, dynamic>? json) {
    // If json is null, return empty car
    if (json == null) {
      return SelfInspectedCarModel.empty();
    }

    return SelfInspectedCarModel(
      id: ModelHelpers.getString(json, '_id'),
      inspectionId: ModelHelpers.getString(json, 'inspectionId'),
      registrationNumber: ModelHelpers.getString(json, 'registrationNumber'),
      make: ModelHelpers.getString(json, 'make'),
      model: ModelHelpers.getString(json, 'model'),
      variant: ModelHelpers.getString(json, 'variant'),
      roadTaxValidity: ModelHelpers.getString(json, 'roadTaxValidity'),
      taxValidTill: ModelHelpers.getDateTime(json, 'taxValidTill'),
      registrationDate: ModelHelpers.getDateTime(json, 'registrationDate'),
      fitnessValidity: ModelHelpers.getDateTime(json, 'fitnessValidity'),
      engineNumber: ModelHelpers.getString(json, 'engineNumber'),
      chassisNumber: ModelHelpers.getString(json, 'chassisNumber'),
      manufacturingDate: ModelHelpers.getDateTime(json, 'manufacturingDate'),
      fuelType: ModelHelpers.getString(json, 'fuelType'),
      cubicCapacity: ModelHelpers.getInt(json, 'cubicCapacity'),
      registrationState: ModelHelpers.getString(json, 'registrationState'),
      registeredRTO: ModelHelpers.getString(json, 'registeredRTO'),
      ownershipSerialNo: ModelHelpers.getInt(json, 'ownershipSerialNo'),
      registeredOwner: ModelHelpers.getString(json, 'registeredOwner'),
      registeredAddressAsPerRC: ModelHelpers.getString(
        json,
        'registeredAddressAsPerRC',
      ),
      hypothecationDetails: ModelHelpers.getString(
        json,
        'hypothecationDetails',
      ),
      financierName: ModelHelpers.getString(json, 'financierName'),
      insuranceValidity: ModelHelpers.getDateTime(json, 'insuranceValidity'),
      rcStatus: ModelHelpers.getString(json, 'rcStatus'),
      blacklistStatus: ModelHelpers.getString(json, 'blacklistStatus'),
      pucValidityDate: ModelHelpers.getDateTime(json, 'pucValidityDate'),
      pucNumber: ModelHelpers.getString(json, 'pucNumber'),
      frontMainImage: ModelHelpers.getString(json, 'frontMainImage'),
      rhsFullImage: ModelHelpers.getString(json, 'rhsFullImage'),
      rearMainImage: ModelHelpers.getString(json, 'rearMainImage'),
      bootFloorImage: ModelHelpers.getString(json, 'bootFloorImage'),
      lhsMainImage: ModelHelpers.getString(json, 'lhsMainImage'),
      engineBayImage: ModelHelpers.getString(json, 'engineBayImage'),
      dashboardImage: ModelHelpers.getString(json, 'dashboardImage'),
      odometer: ModelHelpers.getInt(json, 'odometer'),
      accidentalStatus: ModelHelpers.getString(json, 'accidentalStatus'),
      clutch: ModelHelpers.getString(json, 'clutch'),
      suspension: ModelHelpers.getString(json, 'suspension'),
      steering: ModelHelpers.getString(json, 'steering'),
      brake: ModelHelpers.getString(json, 'brake'),
      ac: ModelHelpers.getString(json, 'ac'),
      expectedDateOfCarHandover: ModelHelpers.getDateTime(
        json,
        'expectedDateOfCarHandover',
      ),
      expectedPrice: ModelHelpers.getInt(json, 'expectedPrice').obs,
      userId: ModelHelpers.getString(json, 'userId'),
      auctionStatus: ModelHelpers.getString(
        json,
        'auctionStatus',
        defaultValue: 'selfInspected',
      ),
      additionalNotes: ModelHelpers.getString(json, 'additionalNotes'),
      priceDiscovery: ModelHelpers.getInt(json, 'priceDiscovery'),
      priceDiscoveryBy: ModelHelpers.getString(json, 'priceDiscoveryBy'),
      highestOffer: ModelHelpers.getInt(json, 'highestOffer').obs,
      highestOfferBy: ModelHelpers.getString(json, 'highestOfferBy').obs,
      auctionStartTime: ModelHelpers.getDateTime(json, 'auctionStartTime'),
      auctionEndTime: ModelHelpers.getDateTime(json, 'auctionEndTime'),
      fixedMargin: ModelHelpers.getDouble(json, 'fixedMargin').obs,
      variableMargin: ModelHelpers.getDouble(json, 'variableMargin').obs,
    );
  }

  // ==================== TO JSON ====================
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    // Add all fields (only if they have values)
    ModelHelpers.addIfNotNull(map, '_id', id);
    map['registrationNumber'] = registrationNumber;
    ModelHelpers.addIfNotNull(map, 'make', make);
    ModelHelpers.addIfNotNull(map, 'model', model);
    ModelHelpers.addIfNotNull(map, 'variant', variant);
    ModelHelpers.addIfNotNull(map, 'roadTaxValidity', roadTaxValidity);
    ModelHelpers.addDateTime(map, 'taxValidTill', taxValidTill);
    ModelHelpers.addDateTime(map, 'registrationDate', registrationDate);
    ModelHelpers.addDateTime(map, 'fitnessValidity', fitnessValidity);
    ModelHelpers.addIfNotNull(map, 'engineNumber', engineNumber);
    ModelHelpers.addIfNotNull(map, 'chassisNumber', chassisNumber);
    ModelHelpers.addDateTime(map, 'manufacturingDate', manufacturingDate);
    ModelHelpers.addIfNotNull(map, 'fuelType', fuelType);
    ModelHelpers.addIfNotNull(map, 'cubicCapacity', cubicCapacity);
    ModelHelpers.addIfNotNull(map, 'registrationState', registrationState);
    ModelHelpers.addIfNotNull(map, 'registeredRTO', registeredRTO);
    ModelHelpers.addIfNotNull(map, 'ownershipSerialNo', ownershipSerialNo);
    ModelHelpers.addIfNotNull(map, 'registeredOwner', registeredOwner);
    ModelHelpers.addIfNotNull(
      map,
      'registeredAddressAsPerRC',
      registeredAddressAsPerRC,
    );
    ModelHelpers.addIfNotNull(
      map,
      'hypothecationDetails',
      hypothecationDetails,
    );
    ModelHelpers.addIfNotNull(map, 'financierName', financierName);
    ModelHelpers.addDateTime(map, 'insuranceValidity', insuranceValidity);
    ModelHelpers.addIfNotNull(map, 'rcStatus', rcStatus);
    ModelHelpers.addIfNotNull(map, 'blacklistStatus', blacklistStatus);
    ModelHelpers.addDateTime(map, 'pucValidityDate', pucValidityDate);
    ModelHelpers.addIfNotNull(map, 'pucNumber', pucNumber);
    map['frontMainImage'] = frontMainImage;
    map['rhsFullImage'] = rhsFullImage;
    map['rearMainImage'] = rearMainImage;
    map['bootFloorImage'] = bootFloorImage;
    map['lhsMainImage'] = lhsMainImage;
    map['engineBayImage'] = engineBayImage;
    map['dashboardImage'] = dashboardImage;
    ModelHelpers.addIfNotNull(map, 'odometer', odometer);
    map['accidentalStatus'] = accidentalStatus;
    map['clutch'] = clutch;
    map['suspension'] = suspension;
    map['steering'] = steering;
    map['brake'] = brake;
    map['ac'] = ac;
    ModelHelpers.addDateTime(
      map,
      'expectedDateOfCarHandover',
      expectedDateOfCarHandover,
    );
    ModelHelpers.addIfNotNull(map, 'expectedPrice', expectedPrice.value);
    ModelHelpers.addIfNotNull(map, 'userId', userId);
    ModelHelpers.addIfNotNull(map, 'auctionStatus', auctionStatus);
    ModelHelpers.addIfNotNull(map, 'additionalNotes', additionalNotes);
    ModelHelpers.addIfNotNull(map, 'priceDiscovery', priceDiscovery);
    ModelHelpers.addIfNotNull(map, 'priceDiscoveryBy', priceDiscoveryBy);
    ModelHelpers.addIfNotNull(map, 'highestOffer', highestOffer.value);
    ModelHelpers.addIfNotNull(map, 'highestOfferBy', highestOfferBy.value);
    ModelHelpers.addIfNotNull(map, 'auctionStartTime', auctionStartTime);
    ModelHelpers.addIfNotNull(map, 'auctionEndTime', auctionEndTime);
    ModelHelpers.addIfNotNull(map, 'fixedMargin', fixedMargin.value);
    ModelHelpers.addIfNotNull(map, 'variableMargin', variableMargin.value);

    return map;
  }

  // ==================== HELPER: Empty Car for Fallback ====================
  factory SelfInspectedCarModel.empty() {
    return SelfInspectedCarModel(
      inspectionId: '',
      make: '',
      model: '',
      variant: '',
      roadTaxValidity: '',
      engineNumber: '',
      chassisNumber: '',
      fuelType: '',
      cubicCapacity: 0,
      registrationState: '',
      registeredRTO: '',
      ownershipSerialNo: 0,
      registeredOwner: '',
      registeredAddressAsPerRC: '',
      hypothecationDetails: '',
      financierName: '',
      rcStatus: '',
      blacklistStatus: '',
      pucNumber: '',
      registrationNumber: '',
      frontMainImage: '',
      rhsFullImage: '',
      rearMainImage: '',
      bootFloorImage: '',
      lhsMainImage: '',
      engineBayImage: '',
      dashboardImage: '',
      accidentalStatus: '',
      clutch: '',
      suspension: '',
      steering: '',
      brake: '',
      ac: '',
      highestOffer: 0.obs,
      highestOfferBy: ''.obs,
      expectedPrice: 0.obs,
      priceDiscovery: 0,
      priceDiscoveryBy: '',
      fixedMargin: 0.0.obs,
      variableMargin: 0.0.obs,
      odometer: 0,
      userId: '',
      auctionStatus: '',
      additionalNotes: '',
    );
  }
}
