class LocationModel {
  final int id;
  final String division;
  final String district;
  final String? upazila;

  LocationModel({
    required this.id,
    required this.division,
    required this.district,
    this.upazila,
  });

  String get displayName =>
      upazila != null && upazila!.isNotEmpty
          ? '$upazila, $district, $division'
          : '$district, $division';

  factory LocationModel.fromJson(Map<String, dynamic> j) => LocationModel(
        id: j['id'],
        division: j['division'],
        district: j['district'],
        upazila: j['upazila'],
      );
}