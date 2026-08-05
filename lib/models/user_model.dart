class UserModel {
  final String uid;
  final String nama;
  final String email;
  final String role;
  final DateTime created_at;
  final DateTime updated_at;

  UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.role,
    required this.created_at,
    required this.updated_at,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      created_at: map['created_at'].toDate(),
      updated_at: map['updated_at'].toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'email': email,
      'role': role,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }
}