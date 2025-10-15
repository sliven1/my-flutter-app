import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:p7/service/cloudinary_service.dart';

class AvatarPicker extends StatefulWidget {

  final double size;


  final BorderRadius borderRadius;


  final bool enablePicker;

  const AvatarPicker({
    Key? key,
    this.size = 120,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.enablePicker = true,
  }) : super(key: key);

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (!mounted) return;
      setState(() => _avatarUrl = data?['avatarUrl'] as String?);
    } catch (e) {
      debugPrint('Avatar loading error: $e');
    }
  }

  Future<void> _pickAndUpload() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 85,
    );
    if (picked == null) return;

    final url = await CloudinaryService.uploadAvatar(filePath: picked.path);
    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Upload failed')));
      }
      return;
    }

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .update({'avatarUrl': url});
    } catch (e) {
      debugPrint('URL conservation error in Firestore: $e');
    }

    if (!mounted) return;
    setState(() => _avatarUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enablePicker ? _pickAndUpload : null,
      child: Hero(
        tag: 'avatar-\${FirebaseAuth.instance.currentUser!.uid}',
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.enablePicker
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            borderRadius: widget.borderRadius,
            image: _avatarUrl != null
                ? DecorationImage(
              image: NetworkImage(_avatarUrl!),
              fit: BoxFit.cover,
            )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: _avatarUrl == null
              ? Icon(
            Icons.person,
            size: widget.size * 0.6,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          )
              : null,
        ),
      ),
    );
  }
}
