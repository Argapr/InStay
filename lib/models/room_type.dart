class RoomType {
  final String id;
  final String name;
  final double pricePerNight;
  final int defaultCapacity;
  final Map<String, dynamic> amenities;
  final int floorNumber;
  final String? imageUrl; // Tambahkan field image

  RoomType({
    required this.id,
    required this.name,
    required this.pricePerNight,
    required this.defaultCapacity,
    required this.amenities,
    required this.floorNumber,
    this.imageUrl,
  });

  factory RoomType.fromMap(Map<String, dynamic> data) {
    return RoomType(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      pricePerNight: (data['price_per_night'] as num).toDouble(),
      defaultCapacity: data['default_capacity'] ?? 0,
      amenities: data['amenities'] ?? {},
      floorNumber: data['floor_number'] ?? 0,
      imageUrl: data['image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price_per_night': pricePerNight,
      'default_capacity': defaultCapacity,
      'amenities': amenities,
      'floor_number': floorNumber,
      'image_url': imageUrl,
    };
  }

  RoomType copyWith({
    String? id,
    String? name,
    double? pricePerNight,
    int? defaultCapacity,
    Map<String, dynamic>? amenities,
    int? floorNumber,
    String? imageUrl,
  }) {
    return RoomType(
      id: id ?? this.id,
      name: name ?? this.name,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      defaultCapacity: defaultCapacity ?? this.defaultCapacity,
      amenities: amenities ?? this.amenities,
      floorNumber: floorNumber ?? this.floorNumber,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
