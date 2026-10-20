import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mask_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Simpan riwayat
  Future<bool> logARSession({required String maskName}) async {
    try {
      final user = _client.auth.currentUser;
      
      // Jika user tidak login, kita tetap kirim dengan userId null
      // (Sesuai schema SQL di atas yang memperbolehkan null untuk testing)
      final data = MaskModel(
        userId: user?.id,
        maskName: maskName,
      );

      await _client.from('ar_sessions').insert(data.toJson());
      return true; // Berhasil
    } catch (e) {
      debugPrint("Error menyimpan session: $e");
      return false; // Gagal
    }
  }
}