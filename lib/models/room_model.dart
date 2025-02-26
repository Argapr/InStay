class Room {
  final int? id;
  final String roomNumber;
  final int roomTypeId;
  final String roomName;
  final String description;
  final int pricePerNight;
  final int capacity;
  final int floorNumber;
  final bool isAvailable;
  final List<String> amenities;
  final List<String> imageUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Room({
    this.id,
    required this.roomNumber,
    required this.roomTypeId,
    required this.roomName,
    required this.description,
    required this.pricePerNight,
    required this.capacity,
    required this.floorNumber,
    required this.isAvailable,
    required this.amenities,
    required this.imageUrls,
    this.createdAt,
    this.updatedAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as int?,
      roomNumber: json['room_number'] as String,
      roomTypeId: json['room_type'] as int,
      roomName: json['room_name'] as String,
      description: json['description'] as String,
      pricePerNight: json['price_per_night'] as int,
      capacity: json['capacity'] as int,
      floorNumber: json['floor_number'] as int,
      isAvailable: json['is_available'] as bool,
      // Ensure amenities is properly converted to List<String>
      amenities: (json['amenities'] is List)
          ? List<String>.from(json['amenities'])
          : (json['amenities'] != null && json['amenities'] is String)
              ? (json['amenities'] as String).split(',').where((item) => item.isNotEmpty).toList()
              : [],
      // Ensure imageUrls is properly converted to List<String>
      imageUrls: (json['image_urls'] is List)
          ? List<String>.from(json['image_urls'])
          : (json['image_urls'] != null && json['image_urls'] is String)
              ? (json['image_urls'] as String).split(',').where((item) => item.isNotEmpty).toList()
              : [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_number': roomNumber,
      'room_type': roomTypeId,
      'room_name': roomName,
      'description': description,
      'price_per_night': pricePerNight,
      'capacity': capacity,
      'floor_number': floorNumber,
      'is_available': isAvailable,
      'amenities': amenities,
      'image_urls': imageUrls,
    };
  }
}
