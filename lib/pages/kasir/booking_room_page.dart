import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'transaction.dart';
import 'package:intl/intl.dart';

class BookingRoomPage extends StatefulWidget {
  const BookingRoomPage({super.key});

  @override
  State<BookingRoomPage> createState() => _BookingRoomPageState();
}

class _BookingRoomPageState extends State<BookingRoomPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> roomTypes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRoomTypes();
  }

  Future<void> fetchRoomTypes() async {
    try {
      final response = await supabase.from('room_types').select('*');
      setState(() {
        roomTypes = response;
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF9a9a9a),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: roomTypes.length,
              itemBuilder: (context, index) {
                final room = roomTypes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomTypeDetailPage(
                          roomType: room,
                        ),
                      ),
                    ),
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 130,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(16),
                              ),
                              image: DecorationImage(
                                image: NetworkImage(room['image_url'] ?? ''),
                                fit: BoxFit.cover,
                                onError: (_, __) => const Icon(
                                  Icons.error,
                                  color: Color(0xFF9a9a9a),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        room['name'] ?? 'No Name',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Color(0xFF9a9a9a),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.people,
                                            size: 16,
                                            color: Color(0xFF9a9a9a),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${room['default_capacity']} Person',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Price per Night',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Rp ${NumberFormat('#,###').format(room['price_per_night'])}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF9a9a9a),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF9a9a9a),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'Detail',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class RoomTypeDetailPage extends StatefulWidget {
  final dynamic roomType;

  const RoomTypeDetailPage({required this.roomType, super.key});

  @override
  State<RoomTypeDetailPage> createState() => _RoomTypeDetailPageState();
}

class _RoomTypeDetailPageState extends State<RoomTypeDetailPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  int availableRooms = 0;
  bool isLoading = true;
  List<String> amenities = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableRooms();
    _parseAmenities();
  }

  Future<void> _fetchAvailableRooms() async {
    final response = await supabase
        .from('rooms')
        .select('id')
        .eq('room_type_id', widget.roomType['id'])
        .eq('is_available', true);

    setState(() {
      availableRooms = response.length;
      isLoading = false;
    });
  }

  void _parseAmenities() {
    final dynamic amenitiesData = widget.roomType['amenities'];

    if (amenitiesData is List) {
      setState(() {
        amenities = List<String>.from(amenitiesData.whereType<String>());
      });
    } else if (amenitiesData is Map) {
      setState(() {
        amenities = amenitiesData.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key.toString())
            .toList();
      });
    } else {
      setState(() => amenities = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF9a9a9a),
        title: Text(
          widget.roomType['name'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF9a9a9a),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Image.network(
                        widget.roomType['image_url'] ?? '',
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 4,
                          shadowColor: Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildDetailItemModern(
                                  Icons.attach_money,
                                  'Price per Night',
                                  'Rp ${NumberFormat('#,###').format(widget.roomType['price_per_night'])}',
                                ),
                                const Divider(height: 24),
                                _buildDetailItemModern(
                                  Icons.people,
                                  'Capacity',
                                  '${widget.roomType['default_capacity']} Person',
                                ),
                                const Divider(height: 24),
                                _buildDetailItemModern(
                                  Icons.apartment,
                                  'Floor',
                                  'Floor ${widget.roomType['floor_number']}',
                                ),
                                const Divider(height: 24),
                                _buildDetailItemModern(
                                  Icons.hotel,
                                  'Room Available',
                                  '$availableRooms Room',
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Amenities',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                amenities.isNotEmpty
                                    ? Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: amenities
                                            .map((amenity) => Chip(
                                                  label: Text(amenity),
                                                  backgroundColor:
                                                      Colors.grey.shade300,
                                                ))
                                            .toList(),
                                      )
                                    : const Text(
                                        'Tidak ada fasilitas yang tersedia',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: availableRooms > 0
                                ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TransactionFormPage(
                                          roomTypeId: widget.roomType['id'],
                                          roomTypeName: widget.roomType['name'],
                                          pricePerNight: widget
                                              .roomType['price_per_night'],
                                        ),
                                      ),
                                    )
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9a9a9a),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Booking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailItemModern(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF9a9a9a).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF9a9a9a),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF9a9a9a),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
