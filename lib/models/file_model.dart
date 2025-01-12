class FileModel {
  final String ipfsHash;
  final String fileName;
  final String description;
  final String ownerAddress;
  final String encryptedKey;
  final String iv;
  final DateTime uploadDate;
  final bool isNFT;

  FileModel({
    required this.ipfsHash,
    required this.fileName,
    required this.description,
    required this.ownerAddress,
    required this.encryptedKey,
    required this.iv,
    required this.uploadDate,
    required this.isNFT,
  });

  Map<String, dynamic> toJson() => {
    'ipfsHash': ipfsHash,
    'fileName': fileName,
    'description': description,
    'ownerAddress': ownerAddress,
    'encryptedKey': encryptedKey,
    'iv': iv,
    'uploadDate': uploadDate.toIso8601String(),
    'isNFT': isNFT,
  };

  factory FileModel.fromJson(Map<String, dynamic> json) => FileModel(
    ipfsHash: json['ipfsHash'],
    fileName: json['fileName'],
    description: json['description'],
    ownerAddress: json['ownerAddress'],
    encryptedKey: json['encryptedKey'],
    iv: json['iv'],
    uploadDate: DateTime.parse(json['uploadDate']),
    isNFT: json['isNFT'],
  );
}
