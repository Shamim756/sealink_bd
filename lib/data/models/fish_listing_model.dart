class FishListingModel {
  final int id;
  final int supplierId;
  final String supplierName;
  final String supplierUsername;
  final int fishCategoryId;
  final String fishNameBn;
  final String fishNameEn;
  final String? fishImage;
  final double quantityKg;
  final double pricePerKg;
  final String? catchDate;
  final List<String> imageUrls;
  final String? videoUrl;
  final String? description;
  final String status;
  final String? division;
  final String? district;
  final String? upazila;
  final String createdAt;
  final int likeCount;
  final int dislikeCount;
  final String? userReaction; // 'LIKE' | 'DISLIKE' | null

  FishListingModel({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.supplierUsername,
    required this.fishCategoryId,
    required this.fishNameBn,
    required this.fishNameEn,
    this.fishImage,
    required this.quantityKg,
    required this.pricePerKg,
    this.catchDate,
    required this.imageUrls,
    this.videoUrl,
    this.description,
    required this.status,
    this.division,
    this.district,
    this.upazila,
    required this.createdAt,
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.userReaction,
  });

  String get locationDisplay {
    final parts = [upazila, district, division]
        .where((e) => e != null && e.isNotEmpty);
    return parts.join(', ');
  }

  String? get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : null;

  FishListingModel copyWith({
    int? likeCount,
    int? dislikeCount,
    String? userReaction,
    bool clearUserReaction = false,
  }) {
    return FishListingModel(
      id: id,
      supplierId: supplierId,
      supplierName: supplierName,
      supplierUsername: supplierUsername,
      fishCategoryId: fishCategoryId,
      fishNameBn: fishNameBn,
      fishNameEn: fishNameEn,
      fishImage: fishImage,
      quantityKg: quantityKg,
      pricePerKg: pricePerKg,
      catchDate: catchDate,
      imageUrls: imageUrls,
      videoUrl: videoUrl,
      description: description,
      status: status,
      division: division,
      district: district,
      upazila: upazila,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      userReaction: clearUserReaction ? null : (userReaction ?? this.userReaction),
    );
  }

  factory FishListingModel.fromJson(Map<String, dynamic> j) {
    List<String> parseImages(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String) {
        try {
          final decoded = raw
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '');
          if (decoded.isEmpty) return [];
          return decoded
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } catch (_) {
          return [];
        }
      }
      return [];
    }

    return FishListingModel(
      id: j['id'],
      supplierId: j['supplier_id'],
      supplierName: j['supplier_name'] ?? 'Unknown',
      supplierUsername: j['supplier_username'] ?? '',
      fishCategoryId: j['fish_category_id'] ?? 0,
      fishNameBn: j['fish_name_bn'] ?? 'Unknown',
      fishNameEn: j['fish_name_en'] ?? 'Unknown',
      fishImage: j['fish_image'],
      quantityKg: double.tryParse(j['quantity_kg'].toString()) ?? 0,
      pricePerKg: double.tryParse(j['price_per_kg'].toString()) ?? 0,
      catchDate: j['catch_date'],
      imageUrls: parseImages(j['image_urls']),
      videoUrl: j['video_url'],
      description: j['description'],
      status: j['status'] ?? 'AVAILABLE',
      division: j['division'],
      district: j['district'],
      upazila: j['upazila'],
      createdAt: j['created_at'] ?? '',
      likeCount: int.tryParse(j['like_count'].toString()) ?? 0,
      dislikeCount: int.tryParse(j['dislike_count'].toString()) ?? 0,
      userReaction: j['user_reaction'],
    );
  }
}