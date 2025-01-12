import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import '../services/web3_service.dart';

class Web3Provider extends ChangeNotifier {
  final Web3Service _web3Service = Web3Service();
  bool isInitialized = false;
  String? currentAddress;

  Future<void> initialize(String privateKey) async {
    try {
      await _web3Service.setCredentials(privateKey);
      final credentials = EthPrivateKey.fromHex(privateKey);
      currentAddress = credentials.address.hexEip55; // Using hexEip55 for checksummed address
      isInitialized = true;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to initialize Web3: $e');
    }
  }

  Future<String> uploadFile(String ipfsHash, String metadata, String encryptedKey) async {
    _checkInitialization();
    return _web3Service.uploadData(ipfsHash, metadata, encryptedKey);
  }

  Future<String> mintNFT(String ipfsHash, String metadata, String encryptedKey) async {
    _checkInitialization();
    return _web3Service.mintNFT(ipfsHash, metadata, encryptedKey);
  }

  Future<List<dynamic>> getUserFiles(String address) async {
    _checkInitialization();
    return _web3Service.getUserFiles(address);
  }

  Future<List<dynamic>> getAccessLogs(String ipfsHash) async {
    _checkInitialization();
    return _web3Service.getAccessLogs(ipfsHash);
  }

  void _checkInitialization() {
    if (!isInitialized) {
      throw Exception('Web3 not initialized. Call initialize() first.');
    }
  }

  Stream<NFTMinted> listenToNFTMintedEvents() {
    _checkInitialization();
    return _web3Service.getNFTMintedEvents();
  }

  Stream<FileUploaded> listenToFileUploadedEvents() {
    _checkInitialization();
    return _web3Service.getFileUploadedEvents();
  }

  Future<void> dispose() async {
    await _web3Service.dispose();
    super.dispose();
  }
}