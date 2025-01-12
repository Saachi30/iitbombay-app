class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String userType;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.userType,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'userType': userType,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      fullName: map['fullName'],
      phoneNumber: map['phoneNumber'],
      userType: map['userType'],
    );
  }
}