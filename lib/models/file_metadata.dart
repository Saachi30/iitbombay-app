class FileMetadata {
  final String ipfsHash;
  final String name;
  final String fileType;
  final String storageType; // 'NFT' or 'IPFS'
  final String ownerAddress;
  final DateTime uploadDate;
  final int accessCount;
  final String encryptedKey;

  FileMetadata({
    required this.ipfsHash,
    required this.name,
    required this.fileType,
    required this.storageType,
    required this.ownerAddress,
    required this.uploadDate,
    required this.accessCount,
    required this.encryptedKey,
  });

  factory FileMetadata.fromMap(Map<String, dynamic> map) {
    return FileMetadata(
      ipfsHash: map['ipfsHash'] ?? '',
      name: map['name'] ?? '',
      fileType: map['fileType'] ?? '',
      storageType: map['storageType'] ?? '',
      ownerAddress: map['ownerAddress'] ?? '',
      uploadDate: DateTime.parse(map['uploadDate'] ?? DateTime.now().toIso8601String()),
      accessCount: map['accessCount'] ?? 0,
      encryptedKey: map['encryptedKey'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ipfsHash': ipfsHash,
      'name': name,
      'fileType': fileType,
      'storageType': storageType,
      'ownerAddress': ownerAddress,
      'uploadDate': uploadDate.toIso8601String(),
      'accessCount': accessCount,
      'encryptedKey': encryptedKey,
    };
  }
}