import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class BlockchainService {
  final String _infuraApiKey = '497503df1a3f4c2fbbc43841db6dcb4d';
  final String _rpcUrl = 'https://polygon-zkevm-testnet.infura.io/v3/497503df1a3f4c2fbbc43841db6dcb4d';
  final int _chainId = 1442;
  final String _contractAddress = '0xB2029969F97dAA4d2A179772Cb8A5a4657614854';
  
  late Web3Client _web3client;
  late DeployedContract _contract;
  late Credentials _credentials;
  
  late ContractEvent _accessGrantedEvent;
  late ContractEvent _accessRevokedEvent;
  late ContractEvent _dataMintedEvent;

  BlockchainService(String walletAddress) {
    _web3client = Web3Client(_rpcUrl, Client());
    _initializeContract();
    _subscribeToEvents();
  }

  Future<void> _initializeContract() async {
    String abiString = await rootBundle.loadString('assets/abi.json');
    var abi = jsonDecode(abiString);
    _contract = DeployedContract(
      ContractAbi.fromJson(jsonEncode(abi), 'DecentralizedDataSharing'),
      EthereumAddress.fromHex(_contractAddress),
    );

    _accessGrantedEvent = _contract.event('AccessGranted');
    _accessRevokedEvent = _contract.event('AccessRevoked');
    _dataMintedEvent = _contract.event('DataMinted');
  }

  void _subscribeToEvents() {
    _web3client.events(FilterOptions.events(
      contract: _contract,
      event: _accessGrantedEvent,
    )).listen((event) {
      try {
        final accessGranted = AccessGrantedEvent.fromEvent(_contract, event);
        print('Access Granted: Owner: ${accessGranted.owner}, Recipient: ${accessGranted.recipient}, IPFS Hash: ${accessGranted.ipfsHash}');
      } catch (e) {
        print('Error parsing AccessGranted event: ${e.toString()}');
      }
    });

    _web3client.events(FilterOptions.events(
      contract: _contract,
      event: _accessRevokedEvent,
    )).listen((event) {
      try {
        final results = _accessRevokedEvent.decodeResults(event.topics!, event.data!);
        print('Access Revoked: Owner: ${results[0]}, IPFS Hash: ${results[1]}');
      } catch (e) {
        print('Error parsing AccessRevoked event: ${e.toString()}');
      }
    });
  }

  Future<String> uploadDataAsNFT(String ipfsHash, String metadata, String encryptedKey) async {
    try {
      final function = _contract.function('mintNFT');
      final gasPrice = await _web3client.getGasPrice();
      
      final transaction = await _web3client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [ipfsHash, metadata, encryptedKey],
          gasPrice: gasPrice,
          maxGas: 500000,
        ),
        chainId: _chainId,
      );
      
      return transaction;
    } catch (e) {
      throw Exception('Failed to mint NFT: ${e.toString()}');
    }
  }

  Future<String> grantAccess(String ipfsHash, String recipientAddress, Duration duration) async {
    try {
      final function = _contract.function('grantAccess');
      final expiration = BigInt.from(
        DateTime.now().add(duration).millisecondsSinceEpoch ~/ 1000
      );
      
      final gasPrice = await _web3client.getGasPrice();
      
      final transaction = await _web3client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [ipfsHash, EthereumAddress.fromHex(recipientAddress), expiration],
          gasPrice: gasPrice,
          maxGas: 300000,
        ),
        chainId: _chainId,
      );
      
      return transaction;
    } catch (e) {
      throw Exception('Failed to grant access: ${e.toString()}');
    }
  }

  Future<TransactionReceipt?> _waitForTransaction(String txHash) async {
    int attempts = 0;
    while (attempts < 20) {
      final receipt = await _web3client.getTransactionReceipt(txHash);
      if (receipt != null) {
        return receipt;
      }
      await Future.delayed(Duration(seconds: 1));
      attempts++;
    }
    throw Exception('Transaction not mined within timeout');
  }
}

class AccessGrantedEvent {
  final String owner;
  final String recipient;
  final String ipfsHash;
  final BigInt expiration;

  AccessGrantedEvent({
    required this.owner,
    required this.recipient,
    required this.ipfsHash,
    required this.expiration,
  });

  factory AccessGrantedEvent.fromEvent(DeployedContract contract, FilterEvent event) {
    if (event.topics == null || event.data == null) {
      throw Exception('Invalid event data');
    }

    try {
      final results = contract.event('AccessGranted').decodeResults(event.topics!, event.data!);
      
      return AccessGrantedEvent(
        owner: (results[0] as EthereumAddress).hex,
        recipient: (results[1] as EthereumAddress).hex,
        ipfsHash: results[2] as String,
        expiration: results[3] as BigInt,
      );
    } catch (e) {
      throw Exception('Failed to decode event data: ${e.toString()}');
    }
  }
}

class AccessLog {
  final String accessor;
  final BigInt timestamp;
  final String action;

  AccessLog({
    required this.accessor,
    required this.timestamp,
    required this.action,
  });
}