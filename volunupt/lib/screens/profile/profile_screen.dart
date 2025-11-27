import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/ui_feedback.dart';
import '../../utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;

  // Campos adicionales del perfil
  String? _phone;
  String? _address;
  String? _emergencyContact;
  String? _emergencyPhone;
  String? _studentCode;
  String? _career;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _displayNameController.text = widget.user.displayName;
          _phone = data['phone'];
          _address = data['address'];
          _emergencyContact = data['emergencyContact'];
          _emergencyPhone = data['emergencyPhone'];
          _studentCode = data['studentCode'];
          _career = data['career'];

          _phoneController.text = _phone ?? '';
          _addressController.text = _address ?? '';
          _emergencyContactController.text = _emergencyContact ?? '';
          _emergencyPhoneController.text = _emergencyPhone ?? '';
        });
      }
    } catch (e) {
      _showErrorSnackBar('No se pudo cargar el perfil. Intenta nuevamente');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await UserService.updateUserProfile(
        userId: widget.user.uid,
        displayName: _displayNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim(),
      );

      setState(() => _isEditing = false);
      _showSuccessSnackBar('¡Listo! Tu perfil ha sido actualizado');
    } catch (e) {
      _showErrorSnackBar(
        'No pudimos actualizar tu perfil. Revisa tu conexión e inténtalo de nuevo',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditStudentInfoDialog() async {
    final studentCodeController = TextEditingController(
      text: _studentCode ?? '',
    );
    final careerController = TextEditingController(text: _career ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Editar Información Académica',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: studentCodeController,
                decoration: InputDecoration(
                  labelText: 'Código de estudiante',
                  hintText: 'Ej: 2021123456',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.badge, color: AppColors.primary),
                  helperText: 'Formato: AAAA + 6 dígitos',
                  helperStyle: const TextStyle(fontSize: 12),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El código de estudiante es requerido';
                  }

                  final regex = RegExp(r'^\d{10}$');
                  if (!regex.hasMatch(value.trim())) {
                    return 'Formato inválido. Debe tener 10 dígitos';
                  }

                  final year = int.tryParse(value.substring(0, 4));
                  if (year == null || year < 2015 || year > 2030) {
                    return 'Año inválido en el código';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: careerController,
                decoration: InputDecoration(
                  labelText: 'Carrera',
                  hintText: 'Ej: Ingeniería de Sistemas',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(
                    Icons.school,
                    color: AppColors.primary,
                  ),
                  helperText: 'Nombre completo de tu carrera',
                  helperStyle: const TextStyle(fontSize: 12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La carrera es requerida';
                  }

                  if (value.trim().length < 5) {
                    return 'Ingresa el nombre completo de la carrera';
                  }

                  if (RegExp(r'^\d+$').hasMatch(value.trim())) {
                    return 'La carrera no puede ser solo números';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Esta información será verificada por el sistema académico de la UPT.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary.withValues(alpha: 0.8),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop({
                  'studentCode': studentCodeController.text.trim(),
                  'career': careerController.text.trim(),
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _updateStudentInfo(
        studentCode: result['studentCode'],
        career: result['career'],
      );
    }

    studentCodeController.dispose();
    careerController.dispose();
  }

  Future<void> _updateStudentInfo({String? studentCode, String? career}) async {
    setState(() => _isLoading = true);

    try {
      await UserService.updateStudentInfo(
        userId: widget.user.uid,
        studentCode: studentCode?.isNotEmpty == true ? studentCode : null,
        career: career?.isNotEmpty == true ? career : null,
      );

      setState(() {
        if (studentCode?.isNotEmpty == true) _studentCode = studentCode;
        if (career?.isNotEmpty == true) _career = career;
      });

      _showSuccessSnackBar(
        '¡Perfecto! Tu información académica ha sido actualizada',
      );
    } catch (e) {
      _showErrorSnackBar(
        'Hubo un problema al guardar los cambios. Inténtalo nuevamente',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    UiFeedback.showSuccess(context, message);
  }

  void _showErrorSnackBar(String message) {
    UiFeedback.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Editar perfil',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: _isLoading ? null : _saveProfile,
              tooltip: 'Guardar cambios',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 20),

                      _buildSectionCard(
                        title: 'Información Básica',
                        icon: Icons.person_outline,
                        children: [
                          _buildInfoField(
                            label: 'Nombre completo',
                            controller: _displayNameController,
                            enabled: _isEditing,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El nombre es requerido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildInfoField(
                            label: 'Email institucional',
                            initialValue: widget.user.email,
                            enabled: false,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoField(
                            label: 'Rol',
                            initialValue: _getRoleDisplayName(widget.user.role),
                            enabled: false,
                          ),
                          if (widget.user.role == UserRole.estudiante) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoField(
                                    label: 'Código de estudiante',
                                    initialValue:
                                        _studentCode ?? 'No especificado',
                                    enabled: false,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _showEditStudentInfoDialog(),
                                    tooltip: 'Editar información académica',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoField(
                              label: 'Carrera',
                              initialValue: _career ?? 'No especificado',
                              enabled: false,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),

                      _buildSectionCard(
                        title: 'Información de Contacto',
                        icon: Icons.contact_phone_outlined,
                        children: [
                          _buildInfoField(
                            label: 'Teléfono',
                            controller: _phoneController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (value.length < 9) {
                                  return 'Ingrese un número válido';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildInfoField(
                            label: 'Dirección',
                            controller: _addressController,
                            enabled: _isEditing,
                            maxLines: 2,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _buildSectionCard(
                        title: 'Contacto de Emergencia',
                        icon: Icons.emergency_outlined,
                        children: [
                          _buildInfoField(
                            label: 'Nombre del contacto',
                            controller: _emergencyContactController,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoField(
                            label: 'Teléfono de emergencia',
                            controller: _emergencyPhoneController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _buildStatisticsSection(),

                      const SizedBox(height: 24),

                      if (_isEditing) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() => _isEditing = false);
                                  _loadUserProfile();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'Guardar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundImage: widget.user.photoURL.isNotEmpty
                  ? NetworkImage(widget.user.photoURL)
                  : null,
              backgroundColor: Colors.white,
              child: widget.user.photoURL.isEmpty
                  ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.user.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              _getRoleDisplayName(widget.user.role),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    TextEditingController? controller,
    String? initialValue,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: enabled ? AppColors.primary : AppColors.textSecondary,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final Future<Map<String, dynamic>> future =
        widget.user.role == UserRole.estudiante
            ? _loadUserStatistics()
            : widget.user.role == UserRole.coordinador
                ? _loadCoordinatorStatistics()
                : _loadAdminStatistics();
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSectionCard(
            title: 'Estadísticas',
            icon: Icons.analytics_outlined,
            children: const [
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final stats = snapshot.data ?? {};

        if (widget.user.role == UserRole.estudiante) {
          return _buildSectionCard(
            title: 'Estadísticas',
            icon: Icons.analytics_outlined,
            children: [
              _buildStatItem(
                'Horas confirmadas',
                '${(stats['totalHours'] ?? 0.0).toStringAsFixed(1)} hrs',
                Icons.access_time_rounded,
                AppColors.primary,
              ),
              const SizedBox(height: 14),
              _buildStatItem(
                'Actividades participadas',
                '${stats['totalActivities'] ?? 0}',
                Icons.event_rounded,
                AppColors.accent,
              ),
              const SizedBox(height: 14),
              _buildStatItem(
                'Certificados obtenidos',
                '${stats['totalCertificates'] ?? 0}',
                Icons.card_membership_rounded,
                AppColors.success,
              ),
              const SizedBox(height: 14),
              _buildStatItem(
                'Actividades pendientes',
                '${stats['pendingActivities'] ?? 0}',
                Icons.pending_rounded,
                AppColors.accent,
              ),
              const SizedBox(height: 14),
              _buildStatItem(
                'Tasa de confirmación',
                '${((stats['confirmationRate'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                Icons.trending_up_rounded,
                AppColors.success,
              ),
            ],
          );
        } else if (widget.user.role == UserRole.coordinador) {
          return _buildSectionCard(
            title: 'Estadísticas de Coordinador',
            icon: Icons.event_available_outlined,
            children: [
              _buildStatItem(
                'Programas creados',
                '${stats['eventsCount'] ?? 0}',
                Icons.event_note_rounded,
                AppColors.primary,
              ),
              const SizedBox(height: 14),
              _buildStatItem(
                'Actividades creadas',
                '${stats['subEventsCount'] ?? 0}',
                Icons.today_rounded,
                AppColors.accent,
              ),
              const SizedBox(height: 14),
              _buildStatItem(
                'Inscritos totales',
                '${stats['registrationsCount'] ?? 0}',
                Icons.group_rounded,
                AppColors.success,
              ),
              const SizedBox(height: 14),
              _buildStatItem(
                'Asistencias pendientes',
                '${stats['pendingAttendanceCount'] ?? 0}',
                Icons.assignment_turned_in_rounded,
                AppColors.accent,
              ),
            ],
          );
        } else {
          return _buildSectionCard(
            title: 'Estadísticas de Administración',
            icon: Icons.admin_panel_settings_rounded,
            children: [
              _buildStatItem(
                'Usuarios totales',
                '${stats['usersCount'] ?? 0}',
                Icons.people_alt_rounded,
                AppColors.primary,
              ),
              const SizedBox(height: 14),
              _buildStatItem(
                'Programas publicados',
                '${stats['publishedEventsCount'] ?? 0}',
                Icons.event_available_rounded,
                AppColors.accent,
              ),
              const SizedBox(height: 14),
              _buildStatItem(
                'Asistencias pendientes',
                '${stats['pendingAttendanceCount'] ?? 0}',
                Icons.assignment_rounded,
                AppColors.accent,
              ),
              const SizedBox(height: 14),
              _buildStatItem(
                'Certificados emitidos',
                '${stats['certificatesCount'] ?? 0}',
                Icons.card_membership_rounded,
                AppColors.success,
              ),
            ],
          );
        }
      },
    );
  }

  Future<Map<String, dynamic>> _loadUserStatistics() async {
    try {
      final futures = await Future.wait([
        HistoryService.getUserTotalConfirmedHours(widget.user.uid),
        HistoryService.getUserAttendanceStats(widget.user.uid),
        CertificateService.getUserCertificates(widget.user.uid).first,
      ]);

      final totalHours = futures[0] as double;
      final attendanceStats = futures[1] as Map<String, dynamic>;
      final certificates = futures[2] as List<CertificateModel>;

      final totalActivities = attendanceStats['totalActivities'] ?? 0;
      final confirmedActivities = attendanceStats['confirmedActivities'] ?? 0;
      final pendingActivities = attendanceStats['pendingActivities'] ?? 0;

      final confirmationRate = totalActivities > 0
          ? (confirmedActivities / totalActivities)
          : 0.0;

      return {
        'totalHours': totalHours,
        'totalActivities': totalActivities,
        'pendingActivities': pendingActivities,
        'confirmationRate': confirmationRate,
        'totalCertificates': certificates.length,
        'confirmedActivities': confirmedActivities,
        'recentActivities': attendanceStats['recentActivities'] ?? 0,
      };
    } catch (e) {
      return {
        'totalHours': 0.0,
        'totalActivities': 0,
        'pendingActivities': 0,
        'confirmationRate': 0.0,
        'totalCertificates': 0,
        'confirmedActivities': 0,
        'recentActivities': 0,
      };
    }
  }

  Future<Map<String, dynamic>> _loadCoordinatorStatistics() async {
    try {
      final futures = await Future.wait([
        EventService.countEventsByCoordinator(widget.user.uid),
        EventService.countSubEventsByCoordinator(widget.user.uid),
        EventService.countRegistrationsByCoordinator(widget.user.uid),
        AttendanceService.countPendingAttendanceForCoordinator(widget.user.uid),
      ]);
      return {
        'eventsCount': futures[0],
        'subEventsCount': futures[1],
        'registrationsCount': futures[2],
        'pendingAttendanceCount': futures[3],
      };
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadAdminStatistics() async {
    try {
      final futures = await Future.wait([
        UserService.countUsers(),
        EventService.countPublishedEvents(),
        AttendanceService.countPendingAttendanceAll(),
        CertificateService.countAllCertificates(),
      ]);
      return {
        'usersCount': futures[0],
        'publishedEventsCount': futures[1],
        'pendingAttendanceCount': futures[2],
        'certificatesCount': futures[3],
      };
    } catch (e) {
      return {};
    }
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.estudiante:
        return 'Estudiante';
      case UserRole.coordinador:
        return 'Coordinador';
      case UserRole.administrador:
        return 'Administrador';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }
}
