class UserModel {
  // // Fields
  // static const String dealer = 'Dealer';
  // static const String customer = 'Customer';
  // static const String salesManager = 'Sales Manager';
  // static const String admin = 'Admin';

  // static const String userStatusPending = 'Pending';
  // static const String userStatusApproved = 'Approved';
  // static const String userStatusRejected = 'Rejected';

  final String id;
  final String userRole;
  final String location;
  final String userName;
  final String email;
  final String? dealershipName;
  final String? entityType;
  final String? primaryContactPerson;
  final String? primaryContactNumber;
  final String? secondaryContactPerson;
  final String? secondaryContactNumber;
  final List<String> addressList;
  final String? image;
  final String password;
  final String phoneNumber;
  final String approvalStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> wishlist;

  UserModel({
    required this.id,
    required this.userRole,
    required this.location,
    required this.userName,
    required this.email,
    this.dealershipName,
    this.entityType,
    this.primaryContactPerson,
    this.primaryContactNumber,
    this.secondaryContactPerson,
    this.secondaryContactNumber,
    required this.addressList,
    this.image,
    required this.password,
    required this.phoneNumber,
    required this.approvalStatus,
    this.createdAt,
    this.updatedAt,
    this.wishlist = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      userRole: json['userRole'] ?? '',
      location: json['location'] ?? '',
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      dealershipName: json['dealershipName'] ?? '',
      entityType: json['entityType'] ?? '',
      primaryContactPerson: json['primaryContactPerson'] ?? '',
      primaryContactNumber: json['primaryContactNumber'] ?? '',
      secondaryContactPerson: json['secondaryContactPerson'],
      secondaryContactNumber: json['secondaryContactNumber'],
      addressList: List<String>.from(json['addressList'] ?? []),
      image: json['image'],
      password: json['password'] ?? '',
      phoneNumber: json['phoneNumber'],
      approvalStatus: json['approvalStatus'] ?? '',
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      wishlist: List<String>.from(json['wishlist'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userRole': userRole,
      'location': location,
      'userName': userName,
      'email': email,
      'dealershipName': dealershipName,
      'entityType': entityType,
      'primaryContactPerson': primaryContactPerson,
      'primaryContactNumber': primaryContactNumber,
      'secondaryContactPerson': secondaryContactPerson,
      'secondaryContactNumber': secondaryContactNumber,
      'addressList': addressList,
      'image': image,
      'password': password,
      'phoneNumber': phoneNumber,
      'approvalStatus': approvalStatus,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'wishlist': wishlist,
    };
  }
}
