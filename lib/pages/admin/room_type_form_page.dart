import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/room_type.dart';
import '../../controllers/room_type_controller.dart';

class RoomTypeFormPage extends StatefulWidget {
  final RoomType? roomType;

  const RoomTypeFormPage({this.roomType, super.key});

  @override
  State<RoomTypeFormPage> createState() => _RoomTypeFormPageState();
}

class _RoomTypeFormPageState extends State<RoomTypeFormPage> {
  static const _primaryColor = Color(0xFF9A9A9A);
  static const _accentColor = Color(0xFF707070);

  final _formKey = GlobalKey<FormState>();
  final _controller = RoomTypeController();
  final _picker = ImagePicker();

  File? _selectedImage;
  int _numberOfRooms = 1;
  bool _isLoading = false;
  Map<String, dynamic> _selectedAmenities = {};

  final List<String> _amenities = [
    'AC',
    'TV',
    'Kulkas',
    'WiFi',
    'Bathtub',
    'Shower Air Panas',
    'Sofa'
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _capacityController;
  late final TextEditingController _floorController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    if (widget.roomType != null) {
      _fetchRoomCount();
    }
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.roomType?.name);
    _priceController = TextEditingController(
      text: widget.roomType?.pricePerNight.toString(),
    );
    _capacityController = TextEditingController(
      text: widget.roomType?.defaultCapacity.toString(),
    );
    _floorController = TextEditingController(
      text: widget.roomType?.floorNumber.toString(),
    );
    _selectedAmenities = widget.roomType?.amenities ?? {};
  }

  Future<void> _fetchRoomCount() async {
    if (widget.roomType?.id == null) return; // Pastikan ID valid

    final response = await Supabase.instance.client
        .from('rooms')
        .select('id')
        .eq('room_type_id', widget.roomType!.id);

    setState(() {
      _numberOfRooms = response.length;
    });
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      _showMessage('Gagal memilih gambar: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final price = double.tryParse(_priceController.text);
      final capacity = int.tryParse(_capacityController.text);
      final floor = int.tryParse(_floorController.text);

      if (price == null || capacity == null || floor == null) {
        throw Exception('Mohon isi semua field dengan benar');
      }

      final roomType = RoomType(
        id: widget.roomType?.id ?? '',
        name: _nameController.text,
        pricePerNight: price,
        defaultCapacity: capacity,
        amenities: _selectedAmenities,
        floorNumber: floor,
        imageUrl: widget.roomType?.imageUrl,
      );

      final imageBytes = _selectedImage?.readAsBytesSync();

      await _controller.saveRoomType(
        roomType: roomType,
        numberOfRooms: _numberOfRooms,
        imageBytes: imageBytes,
        isUpdating: widget.roomType != null,
      );

      if (mounted) {
        _showMessage(
          widget.roomType == null
              ? 'Tipe kamar berhasil ditambahkan'
              : 'Tipe kamar berhasil diperbarui',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
          image: _selectedImage != null
              ? DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                )
              : widget.roomType?.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(widget.roomType!.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _selectedImage == null && widget.roomType?.imageUrl == null
            ? const Icon(Icons.add_a_photo, size: 40, color: _accentColor)
            : null,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String errorText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _accentColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accentColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: validator ??
            (value) {
              if (value?.isEmpty ?? true) return errorText;
              return null;
            },
      ),
    );
  }

  Widget _buildAmenitiesSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amenities:',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: _accentColor),
        ),
        Wrap(
          spacing: 10,
          children: _amenities.map((amenity) {
            return FilterChip(
              label: Text(amenity),
              selected: _selectedAmenities.containsKey(amenity),
              onSelected: (isSelected) {
                setState(() {
                  if (isSelected) {
                    _selectedAmenities[amenity] = true;
                  } else {
                    _selectedAmenities.remove(amenity);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.roomType == null ? 'Add Type Room' : 'Edit Type Room',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_primaryColor, Colors.grey[100]!],
                stops: const [0.0, 0.3],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildImagePicker(),
                      const SizedBox(height: 32),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                controller: _nameController,
                                label: 'Nama Type',
                                errorText: 'Nama harus diisi',
                              ),
                              _buildTextField(
                                controller: _priceController,
                                label: 'Price per night',
                                errorText: 'Harga harus diisi',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.isEmpty ?? true)
                                    return 'Harga harus diisi';
                                  if (double.tryParse(value!) == null) {
                                    return 'Harga harus berupa angka';
                                  }
                                  return null;
                                },
                              ),
                              _buildTextField(
                                controller: _capacityController,
                                label: 'Capacity',
                                errorText: 'Kapasitas harus diisi',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.isEmpty ?? true)
                                    return 'Kapasitas harus diisi';
                                  if (int.tryParse(value!) == null) {
                                    return 'Kapasitas harus berupa angka bulat';
                                  }
                                  return null;
                                },
                              ),
                              _buildTextField(
                                controller: _floorController,
                                label: 'Floor',
                                errorText: 'Lantai harus diisi',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.isEmpty ?? true)
                                    return 'Lantai harus diisi';
                                  if (int.tryParse(value!) == null) {
                                    return 'Lantai harus berupa angka bulat';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Total Room: $_numberOfRooms',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _accentColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildAmenitiesSelection(),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: _primaryColor,
                                  inactiveTrackColor: Colors.grey[300],
                                  thumbColor: _accentColor,
                                  overlayColor: _primaryColor.withOpacity(0.2),
                                ),
                                child: Slider(
                                  value: _numberOfRooms < 1
                                      ? 1
                                      : _numberOfRooms
                                          .toDouble(), // Jaga agar minimal 1
                                  min: 1,
                                  max: 20,
                                  divisions: 19,
                                  label: _numberOfRooms.toString(),
                                  onChanged: (value) {
                                    setState(
                                        () => _numberOfRooms = value.toInt());
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  widget.roomType == null ? 'Save' : 'Update',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _floorController.dispose();
    super.dispose();
  }
}
