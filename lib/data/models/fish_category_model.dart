class FishCategoryModel {
  final int id;
  final String nameBn;
  final String nameEn;
  final String? imageUrl;

  FishCategoryModel({
    required this.id,
    required this.nameBn,
    required this.nameEn,
    this.imageUrl,
  });

  factory FishCategoryModel.fromJson(Map<String, dynamic> j) => FishCategoryModel(
        id: j['id'],
        nameBn: j['name_bn'],
        nameEn: j['name_en'],
        imageUrl: j['image_url'],
      );
}
