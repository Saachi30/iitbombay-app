// lib/models/web3_types.dart
class Web3Transaction {
  final String hash;
  final Map<String, dynamic>? receipt;
  
  Web3Transaction({required this.hash, this.receipt});
  
  factory Web3Transaction.fromJson(Map<String, dynamic> json) {
    return Web3Transaction(
      hash: json['hash'],
      receipt: json['receipt'],
    );
  }
}

class NFTData {
  final String tokenId;
  final String ipfsHash;
  final String metadata;
  
  NFTData({
    required this.tokenId,
    required this.ipfsHash,
    required this.metadata,
  });
  
  factory NFTData.fromJson(Map<String, dynamic> json) {
    return NFTData(
      tokenId: json['tokenId'],
      ipfsHash: json['ipfsHash'],
      metadata: json['metadata'],
    );
  }
}

class AccessLog {
  final String accessor;
  final int timestamp;
  final String action;
  
  AccessLog({
    required this.accessor,
    required this.timestamp,
    required this.action,
  });
  
  factory AccessLog.fromJson(Map<String, dynamic> json) {
    return AccessLog(
      accessor: json['accessor'],
      timestamp: json['timestamp'],
      action: json['action'],
    );
  }
}