import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  // .env ফাইল থেকে API Key লোড করা হচ্ছে
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  final GenerativeModel _model;

  AIService()
      : _model = GenerativeModel(
          model: 'gemini-3.6-flash', 
          apiKey: _apiKey,
          systemInstruction: Content.system(
            'তুমি SeaLink BD অ্যাপের একজন বিশেষজ্ঞ AI সহকারী। '
            'তোমার কাজ শুধুমাত্র মাছ, মাছ চাষ, মাছের রোগ-বালাই, মাছের বাজারদর, এবং বাংলাদেশের মাছের বাজার নিয়ে তথ্য দেওয়া। '
            'যদি ব্যবহারকারী মাছের বাইরে অন্য কোনো বিষয়ে প্রশ্ন করে, তবে ভদ্রভাবে জানাবে যে তুমি শুধু মাছ এবং SeaLink BD প্ল্যাটফর্ম সম্পর্কিত প্রশ্নের উত্তর দিতে পারো। '
            'সবসময় বাংলায় সংক্ষেপে এবং দ্রুত উত্তর দেবে।'
          ),
          generationConfig: GenerationConfig(
            temperature: 0.4, 
            maxOutputTokens: 1000, 
          ),
        );

  Future<String> _generateWithRetry(List<Content> content) async {
    int maxRetries = 2; 
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _model.generateContent(content);
        return response.text ?? 'দুঃখিত, আমি উত্তর দিতে পারছি না।';
      } on GenerativeAIException catch (e) {
        if ((e.message.contains('503') || e.message.contains('429')) && attempt < maxRetries) {
          await Future.delayed(const Duration(seconds: 2)); 
          continue;
        } else {
          return 'ত্রুটি: ${e.message}';
        }
      } catch (e) {
        return 'ত্রুটি: $e';
      }
    }
    return 'সার্ভার বর্তমানে খুব ব্যস্ত। অনুগ্রহ করে কিছুক্ষণ পরে আবার চেষ্টা করুন।';
  }

  Future<String> chat(String message) async {
    try {
      return await _generateWithRetry([Content.text(message)]);
    } catch (e) {
      return 'ত্রুটি: $e';
    }
  }

  Future<String> chatWithImage(String message, File image) async {
    try {
      final imageBytes = await image.readAsBytes();
      final content = [
        Content.multi([
          TextPart(message),
          DataPart('image/jpeg', imageBytes),
        ])
      ];
      return await _generateWithRetry(content);
    } catch (e) {
      return 'ছবি প্রসেস করতে সমস্যা হয়েছে: $e';
    }
  }
}