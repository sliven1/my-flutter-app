import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleSlot {
  final String id;
  final String tutorId;
  final DateTime date;
  final String startTime; // Формат: "09:00"
  final String endTime;   // Формат: "10:00"
  final bool isBooked;
  final String? studentId; // ID ученика, если слот забронирован
  final Timestamp createdAt;

  ScheduleSlot({
    required this.id,
    required this.tutorId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.isBooked = false,
    this.studentId,
    required this.createdAt,
  });

  // Преобразование из Firestore
  factory ScheduleSlot.fromMap(Map<String, dynamic> map, String id) {
    return ScheduleSlot(
      id: id,
      tutorId: map['tutorId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      isBooked: map['isBooked'] ?? false,
      studentId: map['studentId'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  // Преобразование в Firestore
  Map<String, dynamic> toMap() {
    return {
      'tutorId': tutorId,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'isBooked': isBooked,
      'studentId': studentId,
      'createdAt': createdAt,
    };
  }

  // Копирование с изменениями
  ScheduleSlot copyWith({
    String? id,
    String? tutorId,
    DateTime? date,
    String? startTime,
    String? endTime,
    bool? isBooked,
    String? studentId,
    Timestamp? createdAt,
  }) {
    return ScheduleSlot(
      id: id ?? this.id,
      tutorId: tutorId ?? this.tutorId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isBooked: isBooked ?? this.isBooked,
      studentId: studentId ?? this.studentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Проверка, прошел ли слот
  bool get isPast {
    final now = DateTime.now();
    final slotDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(endTime.split(':')[0]),
      int.parse(endTime.split(':')[1]),
    );
    return slotDateTime.isBefore(now);
  }
}
