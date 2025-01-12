// lib/services/ipfs_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class IPFSService {
  static const String PINATA_API_URL = 'https://api.pinata.cloud';
  static const String PINATA_API_KEY = '815cb6c5b936de120de6';
  static const String PINATA_SECRET_KEY = '71b9f2139171591882a5b4cbb9d5ab4846b9b845911a5960111a2cd8ad4a9984';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: PINATA_API_URL,
    headers: {
      'pinata_api_key': PINATA_API_KEY,
      'pinata_secret_api_key': PINATA_SECRET_KEY,
    },
  ));

  Future<Map<String, dynamic>> uploadFile(File file) async {
    try {
      // Generate encryption key
      final key = encrypt.Key.fromSecureRandom(32);
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      // Read and encrypt file
      final fileBytes = await file.readAsBytes();
      final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

      // Prepare form data
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          encrypted.bytes,
          filename: basename(file.path),
        ),
        'pinataMetadata': jsonEncode({
          'name': 'Encrypted_${basename(file.path)}',
        }),
      });

      // Upload to Pinata
      final response = await _dio.post(
        '/pinning/pinFileToIPFS',
        data: formData,
      );

      if (response.statusCode == 200) {
        // Return IPFS hash and encrypted key
        return {
          'ipfsHash': response.data['IpfsHash'],
          'encryptedKey': base64.encode(key.bytes),
          'iv': base64.encode(iv.bytes),
        };
      }

      throw Exception('Failed to upload to IPFS');
    } catch (e) {
      throw Exception('Error uploading to IPFS: $e');
    }
  }

  Future<File> downloadAndDecryptFile(
    String ipfsHash,
    String encryptedKey,
    String iv,
    String savePath,
  ) async {
    try {
      // Download from IPFS
      final response = await _dio.get(
        'https://gateway.pinata.cloud/ipfs/$ipfsHash',
        options: Options(responseType: ResponseType.bytes),
      );

      // Decrypt file
      final key = encrypt.Key.fromBase64(encryptedKey);
      final ivVector = encrypt.IV.fromBase64(iv);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(response.data),
        iv: ivVector,
      );

      // Save decrypted file
      final file = File(savePath);
      await file.writeAsBytes(decrypted);

      return file;
    } catch (e) {
      throw Exception('Error downloading/decrypting file: $e');
    }
  }
}