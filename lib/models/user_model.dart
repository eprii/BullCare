import '../constants/app_constants.dart';
import '../utils/firestore_utils.dart';

class UserModel {
  final String uid;
  final String nama;
  final String email;
  final String role;
  final DateTime created_at;
  final DateTime updated_at;

  const UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.role,
    required this.created_at,
    required this.updated_at,
  });

  bool get isPetugas => role.toLowerCase() == AppConstants.petugasRole;
  bool get isSupervisor => role.toLowerCase() == AppConstants.supervisorRole;

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      nama: map['nama']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? AppConstants.petugasRole,
      created_at: dateTimeFromFirestore(map['created_at']),
      updated_at: dateTimeFromFirestore(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'nama': nama,
      'email': email,
      'role': role,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }
}
