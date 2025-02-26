import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'invoice_generator.dart';

// Constants
class AppColors {
  static const Color primary = Color(0xFF9A9A9A);
  static const Color accent = Color(0xFF707070);
  static const Color background = Color(0xFFF5F5F5);
  static const Color card = Colors.white;
}

class EmailConfig {
  static const String senderEmail = 'argapr24@gmail.com';
  static const String senderPassword = 'uvlk ymyj vevf kzqf';
  static const String senderName = 'InsTay';
}

// Models
class BookingDetails {
  final String customerName;
  final String email;
  final String uniqueNumber;
  final String roomNumber;
  final int nights;
  final double totalPayment;
  final double changeAmount;

  BookingDetails({
    required this.customerName,
    required this.email,
    required this.uniqueNumber,
    required this.roomNumber,
    required this.nights,
    required this.totalPayment,
    required this.changeAmount,
  });
}

// Main Widget
class TransactionFormPage extends StatefulWidget {
  final String roomTypeId;
  final String roomTypeName;
  final dynamic pricePerNight;

  const TransactionFormPage({
    required this.roomTypeId,
    required this.roomTypeName,
    required this.pricePerNight,
    super.key,
  });

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _formControllers = _FormControllers();
  bool _isLoading = false;
  List<dynamic> _availableRooms = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableRooms();
  }

  // Data Fetching
  Future<void> _fetchAvailableRooms() async {
    final response = await _supabase
        .from('rooms')
        .select('id, room_number')
        .eq('room_type_id', widget.roomTypeId)
        .eq('is_available', true);

    setState(() => _availableRooms = response);
  }

  // Transaction Processing
  Future<void> _processTransaction() async {
    if (!_validateTransaction()) return;

    setState(() => _isLoading = true);
    try {
      final bookingDetails = await _createBooking();
      await _updateRoomAvailability(bookingDetails);
      await _logTransaction(bookingDetails);
      await _sendEmailConfirmation(bookingDetails);
      _showSuccessDialog(bookingDetails.email);
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateTransaction() {
    if (!_formKey.currentState!.validate()) return false;
    if (_availableRooms.isEmpty) {
      _showErrorMessage('Tidak ada kamar tersedia!');
      return false;
    }
    return true;
  }

  Future<BookingDetails> _createBooking() async {
    final selectedRoom = _getRandomRoom();
    final nights = int.parse(_formControllers.nights.text);
    final payment = double.parse(_formControllers.payment.text);
    final total = nights * (widget.pricePerNight as double);

    if (payment < total) {
      throw Exception('Pembayaran kurang dari total harga');
    }

    final uniqueNumber = const Uuid().v4().substring(0, 8).toUpperCase();

    await _supabase.from('transactions').insert({
      'room_id': selectedRoom['id'],
      'customer_name': _formControllers.name.text,
      'email': _formControllers.email.text,
      'unique_number': uniqueNumber,
      'payment_amount': total,
      'change_amount': payment - total,
      'duration_nights': nights,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    return BookingDetails(
      customerName: _formControllers.name.text,
      email: _formControllers.email.text,
      uniqueNumber: uniqueNumber,
      roomNumber: selectedRoom['room_number'],
      nights: nights,
      totalPayment: total,
      changeAmount: payment - total,
    );
  }

  Future<void> _updateRoomAvailability(BookingDetails booking) async {
    final selectedRoom = _getRandomRoom();
    await _supabase
        .from('rooms')
        .update({'is_available': false}).eq('id', selectedRoom['id']);
  }

  Future<void> _logTransaction(BookingDetails booking) async {
    final prefs = await SharedPreferences.getInstance();
    final cashierId = prefs.getString('user_id');

    if (cashierId != null) {
      await _supabase.from('log').insert({
        'id_user': cashierId,
        'activity': 'membuat transaksi untuk room ${booking.roomNumber}',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Email Handling
  Future<void> _sendEmailConfirmation(BookingDetails booking) async {
    final smtpServer = gmail(
      EmailConfig.senderEmail,
      EmailConfig.senderPassword,
    );

    try {
      final invoiceFile = await InvoiceGenerator.generateInvoice(
        customerName: booking.customerName,
        email: booking.email,
        uniqueNumber: booking.uniqueNumber,
        roomNumber: booking.roomNumber,
        nights: booking.nights,
        totalPayment: booking.totalPayment,
        changeAmount: booking.changeAmount,
        bookingDate: DateTime.now(),
      );

      final message = _createEmailMessage(booking, invoiceFile);
      await send(message, smtpServer);
    } catch (e) {
      debugPrint('Email Error: $e');
      rethrow;
    }
  }

  Message _createEmailMessage(BookingDetails booking, dynamic invoiceFile) {
    return Message()
      ..from = Address(EmailConfig.senderEmail, EmailConfig.senderName)
      ..recipients.add(booking.email)
      ..subject = 'Invoice Bukti Transaksi'
      ..text = _createEmailBody(booking)
      ..attachments = [
        FileAttachment(invoiceFile)
          ..location = Location.attachment
          ..fileName = 'InStay_booking.pdf'
      ];
  }

  String _createEmailBody(BookingDetails booking) {
    return '''
Dear ${booking.customerName},

Thank you for choosing InStay Hotel for your upcoming stay. We are pleased to confirm your booking.

Your booking details and payment receipt have been attached to this email in PDF format. Please keep this document for your records.

Booking Reference: ${booking.uniqueNumber}
Check-in Duration: ${booking.nights} nights

If you have any questions or need to modify your reservation, please don't hesitate to contact our front desk at:
Phone: +62 821 2534 9737
Email: info@instayhotel.com

We look forward to welcoming you to InStay Hotel.

Best regards,
InStay Hotel Team
''';
  }

  // UI Helpers
  void _showSuccessDialog(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaksi Berhasil'),
        content: Text('Invoice PDF telah dikirim ke email: $email'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $message')),
    );
  }

  dynamic _getRandomRoom() {
    final randomIndex = Random().nextInt(_availableRooms.length);
    return _availableRooms[randomIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoomInfoCard(),
                const SizedBox(height: 32),
                _buildGuestInfoSection(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // UI Components
  PreferredSizeWidget _buildAppBar() => AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text(
          'Booking Payment',
          style: GoogleFonts.poppins(
            color: AppColors.card,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.card),
          onPressed: () => Navigator.pop(context),
        ),
      );

  Widget _buildRoomInfoCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.roomTypeName,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rp ${NumberFormat('#,###').format(widget.pricePerNight)}/night',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      );

  Widget _buildGuestInfoSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guest Information',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          CustomFormField(
            controller: _formControllers.name,
            label: 'Guest Name',
            icon: Icons.person_outline,
            validator: (value) =>
                value!.isEmpty ? 'Please enter guest name' : null,
          ),
          const SizedBox(height: 20),
          CustomFormField(
            controller: _formControllers.email,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                value!.isEmpty ? 'Please enter email address' : null,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomFormField(
                  controller: _formControllers.nights,
                  label: 'Nights',
                  icon: Icons.nights_stay_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomFormField(
                  controller: _formControllers.payment,
                  label: 'Payment Amount',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildSubmitButton() => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _processTransaction,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'Complete Booking',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      );
}

// Form Controllers Helper
class _FormControllers {
  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController nights = TextEditingController();
  final TextEditingController payment = TextEditingController();
}

// Custom Form Field Component
class CustomFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const CustomFormField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(color: AppColors.primary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: AppColors.primary),
        prefixIcon: Icon(icon, color: AppColors.primary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
