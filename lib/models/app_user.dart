import 'package:cloud_firestore/cloud_firestore.dart';

/// A person in Bidly. Stored at users/{uid}.
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;

  /// 'buyer' or 'seller' (chosen at sign up).
  final String role;
  final DateTime? createdAt;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      name: d['name'] as String? ?? '',
      email: d['email'] as String? ?? '',
      role: d['role'] as String? ?? 'buyer',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// The uid is the document id, so it is not stored as a field.
  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };
}
