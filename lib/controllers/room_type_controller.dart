import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room_type.dart';
import 'package:uuid/uuid.dart';

class RoomActivityLogger {
  static String createRoomType(String roomTypeName) {
    return 'Membuat tipe kamar baru: $roomTypeName';
  }

  static String updateRoomType(String roomTypeName) {
    return 'Memperbarui tipe kamar: $roomTypeName';
  }

  static String deleteRoomType(String roomTypeName) {
    return 'Menghapus tipe kamar: $roomTypeName';
  }

  static String createRooms(String roomTypeName, int count) {
    return 'Membuat $count kamar baru untuk tipe: $roomTypeName';
  }

  static String deleteRooms(String roomTypeName, int count) {
    return 'Menghapus $count kamar dari tipe: $roomTypeName';
  }

  static String uploadImage(String roomTypeName) {
    return 'Mengupload gambar untuk tipe kamar: $roomTypeName';
  }

  static String deleteImage(String roomTypeName) {
    return 'Menghapus gambar untuk tipe kamar: $roomTypeName';
  }
}

class RoomTypeController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _bucketName = 'room-images';
  final _uuid = Uuid();

  Future<void> _logActivity(String activity) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('Error logging: No user logged in');
        return;
      }

      await _supabase.from('log').insert({
        'id_user': user.id,
        'activity': activity,
      });
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  Future<int> getLastRoomNumber(String roomTypeName) async {
    try {
      final response = await _supabase
          .from('rooms')
          .select('room_number')
          .like('room_number', '$roomTypeName-%')
          .order('room_number', ascending: false)
          .limit(1)
          .single();

      if (response != null) {
        String number = response['room_number'].toString().split('-').last;
        return int.parse(number);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<String?> uploadImage(Uint8List imageBytes, String roomTypeName) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage.from(_bucketName).uploadBinary(
          fileName, imageBytes,
          fileOptions: FileOptions(contentType: 'image/jpeg'));

      await _logActivity(RoomActivityLogger.uploadImage(roomTypeName));

      return _supabase.storage.from(_bucketName).getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Gagal mengupload gambar: $e');
    }
  }

  Future<void> deleteOldImage(String imageUrl, String roomTypeName) async {
    try {
      final fileName = imageUrl.split('/').last;
      await _supabase.storage.from(_bucketName).remove([fileName]);
      await _logActivity(RoomActivityLogger.deleteImage(roomTypeName));
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  Future<void> saveRoomType({
    required RoomType roomType,
    required int numberOfRooms,
    Uint8List? imageBytes,
    bool isUpdating = false,
  }) async {
    try {
      String? imageUrl = roomType.imageUrl;

      if (imageBytes != null) {
        if (isUpdating && imageUrl != null) {
          await deleteOldImage(imageUrl, roomType.name);
        }
        imageUrl = await uploadImage(imageBytes, roomType.name);
      }

      final String id = isUpdating ? roomType.id : _uuid.v4();
      final updatedRoomType = roomType.copyWith(id: id, imageUrl: imageUrl);

      await _supabase.from('room_types').upsert(updatedRoomType.toMap());

      final activity = isUpdating
          ? RoomActivityLogger.updateRoomType(roomType.name)
          : RoomActivityLogger.createRoomType(roomType.name);
      await _logActivity(activity);

      if (isUpdating) {
        final List<dynamic> existingRooms =
            await _supabase.from('rooms').select('id').eq('room_type_id', id);

        int existingCount = existingRooms.length;

        if (numberOfRooms > existingCount) {
          int lastNumber = await getLastRoomNumber(roomType.name);
          final List<Map<String, dynamic>> newRooms = [];
          for (int i = 1; i <= (numberOfRooms - existingCount); i++) {
            newRooms.add({
              'id': _uuid.v4(),
              'room_type_id': id,
              'room_number':
                  '${roomType.name}-${(lastNumber + i).toString().padLeft(3, '0')}',
              'is_available': true,
            });
          }
          await _supabase.from('rooms').insert(newRooms);
          await _logActivity(RoomActivityLogger.createRooms(
              roomType.name, numberOfRooms - existingCount));
        } else if (numberOfRooms < existingCount) {
          final List<String> roomsToDelete = existingRooms
              .sublist(numberOfRooms)
              .map((r) => r['id'] as String)
              .toList();
          for (String roomId in roomsToDelete) {
            await _supabase.from('rooms').delete().eq('id', roomId);
          }

          await _logActivity(RoomActivityLogger.deleteRooms(
              roomType.name, existingCount - numberOfRooms));
        }
      } else {
        int lastNumber = await getLastRoomNumber(roomType.name);
        final List<Map<String, dynamic>> roomsData = [];
        for (int i = 1; i <= numberOfRooms; i++) {
          roomsData.add({
            'id': _uuid.v4(),
            'room_type_id': id,
            'room_number':
                '${roomType.name}-${(lastNumber + i).toString().padLeft(3, '0')}',
            'is_available': true,
          });
        }
        await _supabase.from('rooms').insert(roomsData);
        await _logActivity(
            RoomActivityLogger.createRooms(roomType.name, numberOfRooms));
      }
    } catch (e) {
      print('Error in saveRoomType: $e');
      rethrow;
    }
  }

  Future<void> deleteRoomType(RoomType roomType) async {
    try {
      if (roomType.imageUrl != null) {
        await deleteOldImage(roomType.imageUrl!, roomType.name);
      }

      await _supabase.from('room_types').delete().eq('id', roomType.id);
      await _logActivity(RoomActivityLogger.deleteRoomType(roomType.name));
    } catch (e) {
      throw Exception('Terjadi kesalahan saat menghapus: $e');
    }
  }

  Future<int> getRoomCount(String roomTypeId) async {
    try {
      final response = await _supabase
          .from('rooms')
          .select('count(*)')
          .eq('room_type_id', roomTypeId)
          .single();

      return response['count'] ?? 0;
    } catch (e) {
      print('Error fetching room count: $e');
      return 0;
    }
  }
}
