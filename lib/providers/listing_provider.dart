import 'package:flutter/material.dart';
import '../data/models/fish_category_model.dart';
import '../data/models/fish_listing_model.dart';
import '../data/models/location_model.dart';
import '../data/repositories/listing_repository.dart';

class ListingProvider extends ChangeNotifier {
  final _repo = ListingRepository();

  List<FishListingModel> _listings = [];
  List<FishCategoryModel> _categories = [];
  List<LocationModel> _locations = [];

  bool _loading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  List<FishListingModel> get listings => _listings;
  List<FishCategoryModel> get categories => _categories;
  List<LocationModel> get locations => _locations;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> loadCategories() async {
    _categories = await _repo.getCategories();
    notifyListeners();
  }

  Future<void> loadLocations() async {
    _locations = await _repo.getLocations();
    notifyListeners();
  }

  Future<void> loadListings({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _listings = [];
      _hasMore = true;
    }

    if (!_hasMore || _loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    final r = await _repo.getListings(page: _currentPage, limit: 10);

    _loading = false;

    if (r['success'] == true) {
      final newListings = r['listings'] as List<FishListingModel>;
      _listings.addAll(newListings);

      final pagination = r['pagination'] as Map<String, dynamic>;
      _totalPages = pagination['totalPages'] ?? 1;
      _hasMore = _currentPage < _totalPages;
      _currentPage++;
    } else {
      _error = r['message'];
    }

    notifyListeners();
  }

  Future<bool> createListing({
    required int fishCategoryId,
    required double quantityKg,
    required double pricePerKg,
    String? catchDate,
    int? locationId,
    List<String>? imageUrls,
    String? videoUrl,
    String? description,
  }) async {
    _loading = true;
    notifyListeners();

    final r = await _repo.createListing(
      fishCategoryId: fishCategoryId,
      quantityKg: quantityKg,
      pricePerKg: pricePerKg,
      catchDate: catchDate,
      locationId: locationId,
      imageUrls: imageUrls,
      videoUrl: videoUrl,
      description: description,
    );

    _loading = false;
    notifyListeners();

    if (r['success'] == true) {
      await loadListings(refresh: true);
      return true;
    }
    _error = r['message'];
    return false;
  }

  Future<String?> uploadImage(dynamic file) async {
    final r = await _repo.uploadImage(file);
    if (r['success'] == true) return r['url'];
    _error = r['message'];
    return null;
  }

  Future<bool> deleteListing(int id) async {
    final r = await _repo.deleteListing(id);
    if (r['success'] == true) {
      _listings.removeWhere((l) => l.id == id);
      notifyListeners();
      return true;
    }
    _error = r['message'];
    return false;
  }
}