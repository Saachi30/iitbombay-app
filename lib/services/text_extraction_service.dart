// lib/services/text_extraction_service.dart
import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TextExtractionService {
  static const String GEMINI_API_KEY = 'YOUR_GEMINI_API_KEY';
  final textDetector = GoogleMlKit.vision.textRecognizer();

  Future<String> extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await textDetector.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      print('Error in OCR: $e');
      return '';
    }
  }

  Future<List<String>> getKeywordsFromText(String text) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$GEMINI_API_KEY'
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': 'Extract important single-word keywords from this text: $text'}
              ]
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final keywordsText = data['candidates'][0]['content']['parts'][0]['text'];
        
        final keywords = keywordsText
            .split(RegExp(r'[\s,]+'))
            .where((word) => word.isNotEmpty)
            .map((word) => word.toLowerCase().trim())
            .toSet()
            .toList();

        return keywords;
      } else {
        print('Error response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting keywords: $e');
      return [];
    }
  }

  void dispose() {
    textDetector.close();
  }
}