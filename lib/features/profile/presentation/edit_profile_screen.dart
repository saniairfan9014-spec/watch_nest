import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/profile_controller.dart';
import '../data/profile_model.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final ProfileModel profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static const _tag = 'EditProfileScreen';

  late final TextEditingController _usernameController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _bioController;
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  File? _pickedImage;
  String? _uploadedUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    developer.log(
      'initState: username=${widget.profile.username}, '
          'fullName=${widget.profile.fullName}, '
          'avatarUrl=${widget.profile.avatarUrl}',
      name: _tag,
    );
    _usernameController = TextEditingController(text: widget.profile.username);
    _fullNameController = TextEditingController(text: widget.profile.fullName ?? '');
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
  }

  @override
  void dispose() {
    developer.log('dispose: disposing controllers', name: _tag);
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(profileUpdaterProvider);
    developer.log(
      'build: isSaving=$isSaving, isUploading=$_isUploading, '
          'hasPickedImage=${_pickedImage != null}, hasUploadedUrl=${_uploadedUrl != null}',
      name: _tag,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: (isSaving || _isUploading) ? null : _save,
            child: (isSaving || _isUploading)
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: _pickImage,
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _pickedImage != null
                              ? FileImage(_pickedImage!)
                              : (widget.profile.avatarUrl != null
                              ? NetworkImage(widget.profile.avatarUrl!)
                              : null),
                          child: (_pickedImage == null &&
                              widget.profile.avatarUrl == null)
                              ? Text(
                            widget.profile.fullName?.isNotEmpty == true
                                ? widget.profile.fullName![0].toUpperCase()
                                : widget.profile.username[0].toUpperCase(),
                            style: const TextStyle(fontSize: 36, color: Colors.grey),
                          )
                              : null,
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: _isUploading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Icon(Icons.edit, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    developer.log('_pickImage: opening gallery picker', name: _tag);
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked == null) {
      developer.log('_pickImage: user cancelled picker', name: _tag);
      return;
    }

    developer.log('_pickImage: picked file path=${picked.path}', name: _tag);

    setState(() {
      _pickedImage = File(picked.path);
      _isUploading = true;
    });

    try {
      final bytes = await _pickedImage!.readAsBytes();
      developer.log('_pickImage: read ${bytes.length} bytes from file', name: _tag);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        developer.log(
          '_pickImage: aborting, no authenticated user found',
          name: _tag,
          level: 900, // warning
        );
        setState(() => _isUploading = false);
        return;
      }

      final fileName =
          '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'avatars/$fileName';
      developer.log(
        '_pickImage: uploading to storage bucket="avatars" path=$path userId=${user.id}',
        name: _tag,
      );

      await Supabase.instance.client.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      developer.log('_pickImage: upload succeeded for path=$path', name: _tag);

      final url =
      Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
      developer.log('_pickImage: resolved public url=$url', name: _tag);

      setState(() {
        _uploadedUrl = url;
        _isUploading = false;
      });
    } catch (e, stackTrace) {
      developer.log(
        '_pickImage: failed to upload image',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000, // error
      );
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    developer.log('_save: validating form', name: _tag);
    if (!_formKey.currentState!.validate()) {
      developer.log('_save: form validation failed', name: _tag);
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      developer.log(
        '_save: aborting, no authenticated user found',
        name: _tag,
        level: 900, // warning
      );
      return;
    }

    final username = _usernameController.text.trim();
    final fullName = _fullNameController.text.trim().isEmpty
        ? null
        : _fullNameController.text.trim();
    final bio = _bioController.text.trim().isEmpty
        ? null
        : _bioController.text.trim();
    final avatarUrl = _uploadedUrl ?? widget.profile.avatarUrl;

    developer.log(
      '_save: calling updateProfile userId=${user.id} username=$username '
          'fullName=$fullName avatarUrl=$avatarUrl bio=$bio',
      name: _tag,
    );

    try {
      await ref.read(profileUpdaterProvider.notifier).updateProfile(
        userId: user.id,
        username: username,
        fullName: fullName,
        avatarUrl: avatarUrl,
        bio: bio,
      );
      developer.log('_save: updateProfile completed successfully', name: _tag);
    } catch (e, stackTrace) {
      developer.log(
        '_save: updateProfile threw an error',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000, // error
      );
      rethrow;
    }

    if (mounted) {
      developer.log('_save: popping EditProfileScreen', name: _tag);
      Navigator.of(context).pop();
    } else {
      developer.log(
        '_save: widget unmounted before navigation pop, skipping',
        name: _tag,
        level: 900,
      );
    }
  }
}