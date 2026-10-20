import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mask_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<MaskModel> _historyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  // Fungsi mengambil data dari Supabase
  Future<void> _fetchHistory() async {
    try {
      final response = await _supabase
          .from('ar_sessions')
          .select()
          .order('created_at', ascending: false); // Urutkan dari yang terbaru

      if (!mounted) return;
      setState(() {
        _historyList = (response as List)
            .map((item) => MaskModel.fromJson(item))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching history: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Penggunaan AR")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyList.isEmpty
              ? const Center(child: Text("Belum ada riwayat."))
              : ListView.builder(
                  itemCount: _historyList.length,
                  itemBuilder: (context, index) {
                    final item = _historyList[index];
                    return ListTile(
                      leading: const Icon(Icons.history, color: Colors.blue),
                      title: Text("Masker: ${item.maskName}"),
                      subtitle: Text(
                        item.createdAt != null
                            ? "Waktu: ${item.createdAt!.toLocal()}"
                            : "Waktu tidak diketahui",
                      ),
                    );
                  },
                ),
    );
  }
}