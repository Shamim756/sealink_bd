import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../datasources/api_client.dart';
import '../models/fish_category_model.dart';
import '../models/fish_listing_model.dart';
import '../models/location_model.dart';

class ListingRepository {
  final _dio = ApiClient().dio;

  Future<List<FishCategoryModel>> getCategories() async {
    try {
      final r = await _dio.get('/fish-categories');
      final list = r.data['categories'] as List;
      return list.map((e) => FishCategoryModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<LocationModel>> getLocations() async {
    try {
      final r = await _dio.get('/locations');
      final list = r.data['locations'] as List;
      return list.map((e) => LocationModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ---- Get Listings (with filters) ----
  Future<Map<String, dynamic>> getListings({
    int page = 1,
    int limit = 10,
    int? fishCategoryId,
    int? locationId,
    double? minPrice,
    double? maxPrice,
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (fishCategoryId != null) params['fish_category_id'] = fishCategoryId;
      if (locationId != null) params['location_id'] = locationId;
      if (minPrice != null) params['min_price'] = minPrice;
      if (maxPrice != null) params['max_price'] = maxPrice;
      if (search != null && search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }

      final r = await _dio.get('/listings', queryParameters: params);
      final listings = (r.data['listings'] as List)
          .map((e) => FishListingModel.fromJson(e))
          .toList();
      return {
        'success': true,
        'listings': listings,
        'pagination': r.data['pagination'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error',
        'listings': <FishListingModel>[],
      };
    }
  }

  Future<FishListingModel?> getListing(int id) async {
    try {
      final r = await _dio.get('/listings/$id');
      return FishListingModel.fromJson(r.data['listing']);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createListing({
    required int fishCategoryId,
    required double quantityKg,
    required double pricePerKg,
    String? catchDate,
    int? locationId,
    List<String>? imageUrls,
    String? videoUrl,
    String? description,
  }) async {
    try {
      final r = await _dio.post('/listings', data: {
        'fish_category_id': fishCategoryId,
        'quantity_kg': quantityKg,
        'price_per_kg': pricePerKg,
        if (catchDate != null) 'catch_date': catchDate,
        if (locationId != null) 'location_id': locationId,
        if (imageUrls != null) 'image_urls': imageUrls,
        if (videoUrl != null) 'video_url': videoUrl,
        if (description != null) 'description': description,
      });
      return {'success': true, 'listing_id': r.data['listing_id']};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> updateListing({
    required int id,
    double? quantityKg,
    double? pricePerKg,
    String? catchDate,
    int? locationId,
    String? description,
    String? status,
  }) async {
    try {
      await _dio.put('/listings/$id', data: {
        if (quantityKg != null) 'quantity_kg': quantityKg,
        if (pricePerKg != null) 'price_per_kg': pricePerKg,
        if (catchDate != null) 'catch_date': catchDate,
        if (locationId != null) 'location_id': locationId,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
      });
      return {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> deleteListing(int id) async {
    try {
      await _dio.delete('/listings/$id');
      return {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> uploadImage(XFile file) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path, filename: file.name),
      });
      final r = await _dio.post('/upload/image', data: formData);
      return {'success': true, 'url': r.data['url']};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Upload failed',
      };
    }
  }

  Future<Map<String, dynamic>> react({
    required int listingId,
    required String type,
  }) async {
    try {
      final r = await _dio.post('/listings/$listingId/react', data: {'type': type});
      return {
        'success': true,
        'likes': r.data['likes'],
        'dislikes': r.data['dislikes'],
        'userReaction': r.data['userReaction'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed',
      };
    }
  }

  Future<List<dynamic>> getComments(int listingId) async {
    try {
      final r = await _dio.get('/listings/$listingId/comments');
      return r.data['comments'] as List;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> postComment({
    required int listingId,
    required String content,
    int? parentCommentId,
  }) async {
    try {
      final r = await _dio.post(
        '/listings/$listingId/comments',
        data: {
          'content': content,
          if (parentCommentId != null) 'parent_comment_id': parentCommentId,
        },
      );
      return {'success': true, 'comment': r.data['comment']};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to post',
      };
    }
  }

  Future<Map<String, dynamic>> getUserRating(int userId) async {
    try {
      final r = await _dio.get('/users/$userId/rating');
      return {
        'success': true,
        'average': r.data['average'],
        'total': r.data['total'],
        'reviews': r.data['reviews'],
      };
    } catch (_) {
      return {
        'success': false,
        'average': 0.0,
        'total': 0,
        'reviews': [],
      };
    }
  }

  Future<Map<String, dynamic>> submitRating({
    required int rateeId,
    int? orderId,
    required int score,
    String? review,
  }) async {
    try {
      final r = await _dio.post('/ratings', data: {
        'ratee_id': rateeId,
        if (orderId != null) 'order_id': orderId,
        'score': score,
        if (review != null) 'review': review,
      });
      return {
        'success': true,
        'new_average': r.data['new_average'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed',
      };
    }
  }
}