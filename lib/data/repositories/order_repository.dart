import 'package:dio/dio.dart';
import '../datasources/api_client.dart';
import '../models/order_model.dart';

class OrderRepository {
  final _dio = ApiClient().dio;

  // ---- Create Order ----
  Future<Map<String, dynamic>> createOrder({
    required int listingId,
    required double quantityKg,
    String? deliveryDate,
    int? deliveryLocationId,
  }) async {
    try {
      final r = await _dio.post('/orders', data: {
        'listing_id': listingId,
        'quantity_kg': quantityKg,
        if (deliveryDate != null) 'delivery_date': deliveryDate,
        if (deliveryLocationId != null) 'delivery_location_id': deliveryLocationId,
      });
      return {
        'success': true,
        'order_id': r.data['order_id'],
        'total_price': r.data['total_price'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to create order',
      };
    }
  }

  // ---- My Orders ----
  Future<List<OrderModel>> getMyOrders() async {
    try {
      final r = await _dio.get('/orders/my');
      final list = r.data['orders'] as List;
      return list.map((e) => OrderModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ---- Get Single Order ----
  Future<Map<String, dynamic>?> getOrder(int id) async {
    try {
      final r = await _dio.get('/orders/$id');
      return r.data['order'];
    } catch (_) {
      return null;
    }
  }

  // ---- Update Order Status (supplier) ----
  Future<Map<String, dynamic>> updateStatus({
    required int orderId,
    required String status,
  }) async {
    try {
      final r = await _dio.put('/orders/$orderId/status', data: {'status': status});
      return {'success': true, 'status': r.data['status']};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to update',
      };
    }
  }
}