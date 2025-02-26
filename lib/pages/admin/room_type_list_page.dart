import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/room_type.dart';
import '../../controllers/room_type_controller.dart';
import 'room_type_form_page.dart';
import 'package:google_fonts/google_fonts.dart';

class RoomTypeListPage extends StatefulWidget {
  const RoomTypeListPage({Key? key}) : super(key: key);

  @override
  _RoomTypeListPageState createState() => _RoomTypeListPageState();
}

class _RoomTypeListPageState extends State<RoomTypeListPage> {
  final RoomTypeController _controller = RoomTypeController();
  late Future<List<RoomType>> _roomTypesFuture;

  // Updated grey color scheme
  final Color backgroundColor = const Color(0xFFF5F5F5);
  final Color cardColor = Colors.white;
  final Color primaryText = const Color(0xFF333333);
  final Color secondaryText = const Color(0xFF9A9A9A);
  final Color accentColor = const Color(0xFF9A9A9A);
  final Color priceColor = const Color(0xFF707070);

  @override
  void initState() {
    super.initState();
    _roomTypesFuture = _fetchRoomTypes();
  }

  Future<List<RoomType>> _fetchRoomTypes() async {
    final response = await Supabase.instance.client
        .from('room_types')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((data) => RoomType.fromMap(data)).toList();
  }

  Future<void> _deleteRoomType(RoomType roomType) async {
    await _controller.deleteRoomType(roomType);
    setState(() {
      _roomTypesFuture = _fetchRoomTypes();
    });
  }

  void _navigateToFormPage({RoomType? roomType}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomTypeFormPage(roomType: roomType),
      ),
    );
    setState(() {
      _roomTypesFuture = _fetchRoomTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            FutureBuilder<List<RoomType>>(
              future: _roomTypesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF9A9A9A),
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.poppins(color: secondaryText),
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hotel_outlined,
                              size: 64, color: secondaryText),
                          const SizedBox(height: 16),
                          Text(
                            'No rooms available',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final roomTypes = snapshot.data!;
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final roomType = roomTypes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: GestureDetector(
                            onTap: () =>
                                _navigateToFormPage(roomType: roomType),
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF9A9A9A)
                                        .withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  children: [
                                    // Room Image
                                    Positioned.fill(
                                      child: roomType.imageUrl != null
                                          ? Hero(
                                              tag: 'room_${roomType.id}',
                                              child: Image.network(
                                                roomType.imageUrl!,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Container(
                                              color:
                                                  accentColor.withOpacity(0.1),
                                              child: Icon(
                                                Icons.image_outlined,
                                                size: 48,
                                                color: accentColor,
                                              ),
                                            ),
                                    ),
                                    // Gradient Overlay
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              const Color(0xFF333333)
                                                  .withOpacity(0.7),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Content
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    roomType.name,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                              0xFF9A9A9A)
                                                          .withOpacity(0.9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Text(
                                                      'Rp ${roomType.pricePerNight.toStringAsFixed(0)}/night',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: Colors.white
                                                      .withOpacity(0.3),
                                                  child: IconButton(
                                                    icon: const Icon(Icons.edit,
                                                        color: Colors.white),
                                                    onPressed: () =>
                                                        _navigateToFormPage(
                                                            roomType: roomType),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                CircleAvatar(
                                                  backgroundColor: Colors.white
                                                      .withOpacity(0.3),
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.white),
                                                    onPressed: () =>
                                                        _deleteRoomType(
                                                            roomType),
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
                          ),
                        );
                      },
                      childCount: roomTypes.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
          onPressed: () => _navigateToFormPage(),
          backgroundColor: const Color(0xFF9A9A9A),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9A9A9A),
                  const Color(0xFF707070),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.add,
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
