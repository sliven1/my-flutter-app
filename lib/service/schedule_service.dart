import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/schedule_slot.dart';

class ScheduleService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получить все слоты преподавателя
  Stream<List<ScheduleSlot>> getTutorSchedule(String tutorId) {
    return _firestore
        .collection('slots')
        .where('tutorId', isEqualTo: tutorId)
        .orderBy('date')
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ScheduleSlot.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Получить слоты преподавателя на конкретную дату
  Stream<List<ScheduleSlot>> getTutorScheduleByDate(
    String tutorId,
    DateTime date,
  ) {
    final targetDate = DateTime(date.year, date.month, date.day);

    return _firestore
        .collection('slots')
        .where('tutorId', isEqualTo: tutorId)
        .snapshots()
        .map((snapshot) {
      debugPrint('🔍 Total slots for tutor: ${snapshot.docs.length}');

      // Получаем все слоты преподавателя
      final allSlots = snapshot.docs
          .map((doc) => ScheduleSlot.fromMap(doc.data(), doc.id))
          .toList();

      debugPrint('📅 Target date: $targetDate');

      // Фильтруем по дате в коде
      final filteredSlots = allSlots.where((slot) {
        final slotDate = DateTime(
          slot.date.year,
          slot.date.month,
          slot.date.day,
        );
        debugPrint('   Slot date: $slotDate, matches: ${slotDate.isAtSameMomentAs(targetDate)}');
        return slotDate.isAtSameMomentAs(targetDate);
      }).toList();

      debugPrint('✅ Filtered slots: ${filteredSlots.length}');

      // Сортируем по времени
      filteredSlots.sort((a, b) {
        final timeCompare = a.startTime.compareTo(b.startTime);
        if (timeCompare != 0) return timeCompare;
        return a.endTime.compareTo(b.endTime);
      });

      return filteredSlots;
    });
  }

  // Добавить новый слот
  Future<void> addSlot({
    required String tutorId,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      // Обнуляем время, оставляем только дату
      final dateOnly = DateTime(date.year, date.month, date.day);

      final slot = ScheduleSlot(
        id: '',
        tutorId: tutorId,
        date: dateOnly,
        startTime: startTime,
        endTime: endTime,
        isBooked: false,
        createdAt: Timestamp.now(),
      );

      await _firestore.collection('slots').add(slot.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding slot: $e');
      rethrow;
    }
  }

  // Удалить слот
  Future<void> deleteSlot(String slotId) async {
    try {
      await _firestore.collection('slots').doc(slotId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting slot: $e');
      rethrow;
    }
  }

  // Обновить слот
  Future<void> updateSlot({
    required String slotId,
    DateTime? date,
    String? startTime,
    String? endTime,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (date != null) updates['date'] = Timestamp.fromDate(date);
      if (startTime != null) updates['startTime'] = startTime;
      if (endTime != null) updates['endTime'] = endTime;

      if (updates.isNotEmpty) {
        await _firestore.collection('slots').doc(slotId).update(updates);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating slot: $e');
      rethrow;
    }
  }

  // Забронировать слот (для ученика)
  Future<void> bookSlot(String slotId, String studentId) async {
    try {
      await _firestore.collection('slots').doc(slotId).update({
        'isBooked': true,
        'studentId': studentId,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error booking slot: $e');
      rethrow;
    }
  }

  // Отменить бронирование
  Future<void> cancelBooking(String slotId) async {
    try {
      await _firestore.collection('slots').doc(slotId).update({
        'isBooked': false,
        'studentId': null,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      rethrow;
    }
  }

  // Получить доступные (не забронированные) слоты преподавателя
  Stream<List<ScheduleSlot>> getAvailableSlots(String tutorId) {
    return _firestore
        .collection('slots')
        .where('tutorId', isEqualTo: tutorId)
        .where('isBooked', isEqualTo: false)
        .orderBy('date')
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ScheduleSlot.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}
