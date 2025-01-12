class TransactionModel {
  final String hash;
  final String from;
  final String to;
  final DateTime timestamp;
  final String status;

  TransactionModel({
    required this.hash,
    required this.from,
    required this.to,
    required this.timestamp,
    required this.status,
  });
}