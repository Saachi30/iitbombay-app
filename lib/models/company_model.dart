class CompanyModel {
  final String uid;
  final String email;
  final String companyName;
  final String gstNumber;
  final bool isAuthorized;

  CompanyModel({
    required this.uid,
    required this.email,
    required this.companyName,
    required this.gstNumber,
    this.isAuthorized = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'companyName': companyName,
      'gstNumber': gstNumber,
      'isAuthorized': isAuthorized,
    };
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      uid: map['uid'],
      email: map['email'],
      companyName: map['companyName'],
      gstNumber: map['gstNumber'],
      isAuthorized: map['isAuthorized'] ?? false,
    );
  }
}