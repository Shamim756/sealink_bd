import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  static final TFLiteService _instance = TFLiteService._internal();
  factory TFLiteService() => _instance;
  TFLiteService._internal();

  Interpreter? _interpreter;
  bool _isLoaded = false;

  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/demand_model.tflite');
      _isLoaded = true;
      print('✅ TFLite Model Loaded');
    } catch (e) {
      print('❌ Failed to load TFLite model: $e');
    }
  }

  double predictDemand(int month, int fishTypeId, double pastDemandKg) {
    if (_interpreter == null) return 0.0;

    var input = [
      [month.toDouble(), fishTypeId.toDouble(), pastDemandKg]
    ];
    var output = List.filled(1, List.filled(1, 0.0));

    try {
      _interpreter!.run(input, output);
      return output[0][0];
    } catch (e) {
      print('Prediction error: $e');
      return 0.0;
    }
  }
}