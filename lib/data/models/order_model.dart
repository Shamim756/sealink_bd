class OrderModel {
  final int id;
  final int buyerId;
  final int supplierId;
  final int listingId;
  final double totalPrice;
  final String? deliveryDate;
  final String status;
  final String createdAt;
  final List<String> imageUrls;
  final int fishCategoryId;
  final String fishNameBn;
  final String fishNameEn;

  // Buyer sees supplier; supplier sees buyer
  final String? supplierName;
  final String? supplierUsername;
  final String? buyerName;
  final String? buyerUsername;
  final String? buyerPhone;

  // Location
  final String? division;
  final String? district;
  final String? upazila;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.supplierId,
    required this.listingId,
    required this.totalPrice,
    this.deliveryDate,
    required this.status,
    required this.createdAt,
    required this.imageUrls,
    required this.fishCategoryId,
    required this.fishNameBn,
    required this.fishNameEn,
    this.supplierName,
    this.supplierUsername,
    this.buyerName,
    this.buyerUsername,
    this.buyerPhone,
    this.division,
    this.district,
    this.upazila,
  });

  String? get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : null;

  String get locationDisplay {
    final parts = [upazila, district, division]
        .where((e) => e != null && e.isNotEmpty);
    return parts.join(', ');
  }

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'IN_TRANSIT':
        return 'In Transit';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  static List<String> parseImages(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String) {
      try {
        final decoded =
            raw.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
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

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
        id: j['id'],
        buyerId: j['buyer_id'],
        supplierId: j['supplier_id'],
        listingId: j['listing_id'],
        totalPrice: double.tryParse(j['total_price'].toString()) ?? 0,
        deliveryDate: j['delivery_date'],
        status: j['status'] ?? 'PENDING',
        createdAt: j['created_at'] ?? '',
        imageUrls: parseImages(j['image_urls']),
        fishCategoryId: j['fish_category_id'] ?? 0,
        fishNameBn: j['fish_name_bn'] ?? 'Unknown',
        fishNameEn: j['fish_name_en'] ?? 'Unknown',
        supplierName: j['supplier_name'],
        supplierUsername: j['supplier_username'],
        buyerName: j['buyer_name'],
        buyerUsername: j['buyer_username'],
        buyerPhone: j['buyer_phone'],
        division: j['division'],
        district: j['district'],
        upazila: j['upazila'],
      );
}