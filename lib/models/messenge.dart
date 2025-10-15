
import 'package:cloud_firestore/cloud_firestore.dart';


class Message {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final Timestamp timestamp;
  final String type;
  final String? fileName;
  final int? fileSize;
  final Duration? duration;

  Message({
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.message,
    required this.timestamp,
    required this.type,
    this.fileName,
    this.fileSize,
    this.duration,
  }) : assert(type == 'text' || type == 'image' || type == 'audio');

  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'receiverID': receiverID,
      'message': message,
      'timestamp': timestamp,
      'type': type,
      'fileName': fileName,
      'fileSize': fileSize,
      'duration': duration?.inSeconds,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderID: map['senderID'] ?? '',
      senderEmail: map['senderEmail'] ?? '',
      receiverID: map['receiverID'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      type: map['type'] ?? 'text',
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      duration: map['duration'] != null
          ? Duration(seconds: map['duration'] as int)
          : null,
    );
  }

  bool get isText => type == 'text';
  bool get isImage => type == 'image';
  bool get isAudio => type == 'audio';
}