import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String username;
  final DateTime birthDate;
  final String city;
  final String role;
  final String bio;
  final String? avatarUrl;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.username,
    required this.birthDate,
    required this.city,
    required this.role,
    required this.bio,
    this.avatarUrl,
  });

  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final Timestamp ts = data['birthDate'] as Timestamp;
    final DateTime date = ts.toDate();

    return UserProfile(
      uid:        data['uid'] as String,
      name:       data['name'] as String,
      email:      data['email'] as String,
      username:   data['username'] as String,
      birthDate:  date,
      city:       data['city'] as String? ?? 'Не указан',
      role:       data['role'] as String? ?? 'Другое',
      bio:        data['bio'] as String? ?? '',
      avatarUrl:  data['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid':        uid,
      'name':       name,
      'email':      email,
      'username':   username,
      'birthDate':  Timestamp.fromDate(birthDate),
      'city':       city,
      'role':       role,
      'bio':        bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }

  // Копирование с изменениями
  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? username,
    DateTime? birthDate,
    String? city,
    String? role,
    String? bio,
    String? avatarUrl,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      birthDate: birthDate ?? this.birthDate,
      city: city ?? this.city,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}