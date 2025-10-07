import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/user_profile_entity.dart';
import '../providers/profile_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentCodeController = TextEditingController();
  final _careerController = TextEditingController();
  final _semesterController = TextEditingController();

  bool _isLoading = false;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    final userProfile = ref.read(userProfileProvider);
    userProfile.whenData((profile) {
      if (profile != null) {
        _nameController.text = profile.name;
        _phoneController.text = profile.phone ?? '';
        _studentCodeController.text = profile.studentCode ?? '';
        _careerController.text = profile.career ?? '';
        _semesterController.text = profile.semester?.toString() ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _studentCodeController.dispose();
    _careerController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuario no autenticado'));
          }

          return userProfile.when(
            data: (profile) => _buildForm(profile),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error de autenticación: $error'),
        ),
      ),
    );
  }

  Widget _buildForm(UserProfileEntity? profile) {
    final currentUser = ref.read(currentUserProvider).value;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildProfilePhoto(profile),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'El nombre y correo no pueden modificarse. Solo puedes editar tu teléfono y detalles académicos.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _nameController,
              label: 'Nombre completo',
              icon: Icons.person,
              readOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: currentUser?.email ?? '',
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                suffixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Teléfono',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _studentCodeController,
              label: 'Código de estudiante',
              icon: Icons.badge,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _careerController,
              label: 'Carrera',
              icon: Icons.school,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _semesterController,
              label: 'Semestre',
              icon: Icons.grade,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhoto(UserProfileEntity? profile) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(context).primaryColor,
            backgroundImage: _selectedImagePath != null
                ? NetworkImage(_selectedImagePath!)
                : (profile?.photoUrl != null
                    ? NetworkImage(profile!.photoUrl!)
                    : null),
            child: (profile?.photoUrl == null && _selectedImagePath == null)
                ? const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: _pickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.shade100 : null,
        suffixIcon: readOnly ? const Icon(Icons.lock_outline, color: Colors.grey) : null,
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;

      final currentProfile = ref.read(userProfileProvider).value;
      
      final updatedProfile = UserProfileEntity(
        id: currentUser.id,
        name: currentProfile?.name ?? currentUser.name,
        email: currentUser.email,
        role: currentUser.role,
        photoUrl: currentProfile?.photoUrl,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        studentCode: _studentCodeController.text.trim().isEmpty ? null : _studentCodeController.text.trim(),
        career: _careerController.text.trim().isEmpty ? null : _careerController.text.trim(),
        semester: _semesterController.text.trim().isEmpty ? 1 : int.tryParse(_semesterController.text.trim()) ?? 1,
        createdAt: currentProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        biometricEnabled: currentProfile?.biometricEnabled ?? false,
        notificationsEnabled: currentProfile?.notificationsEnabled ?? true,
      );

      await ref.read(profileNotifierProvider.notifier).updateProfile(updatedProfile);

      if (_selectedImagePath != null) {
        await ref.read(profileNotifierProvider.notifier).updateProfilePhoto(currentUser.id, _selectedImagePath!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar perfil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}