import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Web3Service {
  static const String rpcUrl = 'http://127.0.0.1:7545'; // Ganache RPC URL
  static const String wsUrl = 'ws://127.0.0.1:7545';    // Ganache WebSocket URL
  static const String contractAddress = '0x376Fb6EB51F0860d699EC73e49CB79AF7F9fE0f8';

  late final Web3Client _web3client;
  late final String _abiCode;
  late final EthereumAddress _contractAddress;
  late final DeployedContract _contract;
  late final Credentials _credentials;

  // Contract events
  late final ContractEvent _nftMintedEvent;
  late final ContractEvent _fileUploadedEvent;
  late final ContractEvent _accessGrantedEvent;

  // Contract functions
  late final ContractFunction _mintNFT;
  late final ContractFunction _uploadData;
  late final ContractFunction _grantAccess;
  late final ContractFunction _getUserUploadedData;
  late final ContractFunction _getAccessLogs;

  bool _isInitialized = false;

  Web3Service() {
    _initializeWeb3Client();
  }

  void _initializeWeb3Client() {
    _web3client = Web3Client(
      rpcUrl,
      Client(),
      socketConnector: () {
        return WebSocketChannel.connect(Uri.parse(wsUrl)).cast<String>();
      },
    );
  }

  Future<void> initialSetup() async {
    if (_isInitialized) return;

    try {
      // Load contract ABI
      _abiCode = await rootBundle.loadString('assets/contracts/DecentralizedDataSharing.json');
      final contractJson = jsonDecode(_abiCode);
      _contractAddress = EthereumAddress.fromHex(contractAddress);
      
      // Create contract instance
      _contract = DeployedContract(
        ContractAbi.fromJson(jsonEncode(contractJson['abi']), 'DecentralizedDataSharing'),
        _contractAddress,
      );

      // Initialize contract events
      _nftMintedEvent = _contract.event('NFTMinted');
      _fileUploadedEvent = _contract.event('FileUploaded');
      _accessGrantedEvent = _contract.event('AccessGranted');

      // Initialize contract functions
      _mintNFT = _contract.function('mintNFT');
      _uploadData = _contract.function('uploadData');
      _grantAccess = _contract.function('grantAccess');
      _getUserUploadedData = _contract.function('getUserUploadedData');
      _getAccessLogs = _contract.function('getAccessLogs');

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Web3Service: $e');
    }
  }

  Future<void> setCredentials(String privateKey) async {
    await _ensureInitialized();
    _credentials = EthPrivateKey.fromHex(privateKey);
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialSetup();
    }
  }

  Future<String> mintNFT(String ipfsHash, String metadata, String encryptedKey) async {
    await _ensureInitialized();
    
    final transaction = Transaction.callContract(
      contract: _contract,
      function: _mintNFT,
      parameters: [ipfsHash, metadata, encryptedKey],
    );

    final result = await _web3client.sendTransaction(
      _credentials,
      transaction,
      chainId: 1337, // Ganache default chainId
    );

    return result;
  }

  Future<String> uploadData(String ipfsHash, String metadata, String encryptedKey) async {
    await _ensureInitialized();
    
    final transaction = Transaction.callContract(
      contract: _contract,
      function: _uploadData,
      parameters: [ipfsHash, metadata, encryptedKey],
    );

    final result = await _web3client.sendTransaction(
      _credentials,
      transaction,
      chainId: 1337,
    );

    return result;
  }

  Future<String> grantAccess(String ipfsHash, String recipientAddress, BigInt expiration) async {
    await _ensureInitialized();
    
    final transaction = Transaction.callContract(
      contract: _contract,
      function: _grantAccess,
      parameters: [
        ipfsHash,
        EthereumAddress.fromHex(recipientAddress),
        expiration,
      ],
    );

    final result = await _web3client.sendTransaction(
      _credentials,
      transaction,
      chainId: 1337,
    );

    return result;
  }

  Future<List<dynamic>> getUserFiles(String userAddress) async {
    await _ensureInitialized();
    
    final result = await _web3client.call(
      contract: _contract,
      function: _getUserUploadedData,
      params: [EthereumAddress.fromHex(userAddress)],
    );

    return result;
  }

  Future<List<dynamic>> getAccessLogs(String ipfsHash) async {
    await _ensureInitialized();
    
    final result = await _web3client.call(
      contract: _contract,
      function: _getAccessLogs,
      params: [ipfsHash],
    );

    return result;
  }

  Stream<NFTMinted> getNFTMintedEvents() {
    if (!_isInitialized) {
      throw Exception('Web3Service not initialized. Call initialSetup() first.');
    }
    
    return _web3client
        .events(FilterOptions.events(contract: _contract, event: _nftMintedEvent))
        .map((event) => NFTMinted.fromEvent(event));
  }

  Stream<FileUploaded> getFileUploadedEvents() {
    if (!_isInitialized) {
      throw Exception('Web3Service not initialized. Call initialSetup() first.');
    }
    
    return _web3client
        .events(FilterOptions.events(contract: _contract, event: _fileUploadedEvent))
        .map((event) => FileUploaded.fromEvent(event));
  }

  Future<void> dispose() async {
    await _web3client.dispose();
  }
}

// Event models remain the same
class NFTMinted {
  final String? transactionHash;
  final EthereumAddress? address;
  final String? blockHash;
  final int? blockNum;
  final String? data;
  final List<String?>? topics;

  NFTMinted({
    required this.transactionHash,
    required this.address,
    required this.blockHash,
    required this.blockNum,
    required this.data,
    this.topics,
  });

  static NFTMinted fromEvent(FilterEvent event) {
    return NFTMinted(
      transactionHash: event.transactionHash,
      address: event.address,
      blockHash: event.blockHash,
      blockNum: event.blockNum,
      data: event.data,
      topics: event.topics?.cast<String?>(),
    );
  }
}

class FileUploaded {
  final String? transactionHash;
  final EthereumAddress? address;
  final String? blockHash;
  final int? blockNum;
  final String? data;
  final List<String?>? topics;

  FileUploaded({
    required this.transactionHash,
    required this.blockHash,
    required this.address,
    required this.blockNum,
    required this.data,
    this.topics,
  });

  static FileUploaded fromEvent(FilterEvent event) {
    return FileUploaded(
      transactionHash: event.transactionHash,
      address: event.address,
      blockHash: event.blockHash,
      blockNum: event.blockNum,
      data: event.data,
      topics: event.topics?.cast<String?>(),
    );
  }
}