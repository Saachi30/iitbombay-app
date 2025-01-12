class AccessRequestModel {
  final String id;
  final String userName;
  final String fileName;
  final String status;
  final DateTime requestDate;
  
  AccessRequestModel({
    required this.id,
    required this.userName,
    required this.fileName,
    required this.status,
    required this.requestDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userName': userName,
      'fileName': fileName,
      'status': status,
      'requestDate': requestDate.toIso8601String(),
    };
  }

  factory AccessRequestModel.fromMap(Map<String, dynamic> map) {
    return AccessRequestModel(
      id: map['id'],
      userName: map['userName'],
      fileName: map['fileName'],
      status: map['status'],
      requestDate: DateTime.parse(map['requestDate']),
    );
  }
}