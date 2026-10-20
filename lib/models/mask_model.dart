class MaskModel {
  final int? id;
  final String? userId;
  final String maskName;
  final DateTime? createdAt;

  MaskModel({
    this.id,
    this.userId,
    required this.maskName,
    this.createdAt,
  });

  // Fungsi untuk mengubah data dari Supabase (JSON) menjadi objek Dart
  factory MaskModel.fromJson(Map<String, dynamic> json) {
    return MaskModel(
      id: json['id'],
      userId: json['user_id'],
      maskName: json['mask_name'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  // Fungsi untuk mengubah objek Dart menjadi JSON untuk dikirim ke Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'mask_name': maskName,
    };
  }
}