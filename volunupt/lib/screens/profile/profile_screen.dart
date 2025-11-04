import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../../services/services.dart';

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
      _showErrorSnackBar('Error al cargar el perfil: $e');
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
      _showErrorSnackBar('No pudimos actualizar tu perfil. Revisa tu conexión e inténtalo de nuevo');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditStudentInfoDialog() async {
    final studentCodeController = TextEditingController(text: _studentCode ?? '');
    final careerController = TextEditingController(text: _career ?? '');
    final formKey = GlobalKey<FormState>();
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Editar Información Académica',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: studentCodeController,
                decoration: const InputDecoration(
                  labelText: 'Código de estudiante',
                  hintText: 'Ej: 2021123456',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                  helperText: 'Formato: AAAA + 6 dígitos',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El código de estudiante es requerido';
                  }
                  
                  // Validar formato: 4 dígitos del año + 6 dígitos
                  final regex = RegExp(r'^\d{10}$');
                  if (!regex.hasMatch(value.trim())) {
                    return 'Formato inválido. Debe tener 10 dígitos';
                  }
                  
                  // Validar que el año sea razonable (2015-2030)
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
                decoration: const InputDecoration(
                  labelText: 'Carrera',
                  hintText: 'Ej: Ingeniería de Sistemas',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                  helperText: 'Nombre completo de tu carrera',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La carrera es requerida';
                  }
                  
                  if (value.trim().length < 5) {
                    return 'Ingresa el nombre completo de la carrera';
                  }
                  
                  // Validar que no contenga solo números
                  if (RegExp(r'^\d+$').hasMatch(value.trim())) {
                    return 'La carrera no puede ser solo números';
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta información será verificada por el sistema académico de la UPT.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
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
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
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

  Future<void> _updateStudentInfo({
    String? studentCode,
    String? career,
  }) async {
    setState(() => _isLoading = true);

    try {
      await UserService.updateStudentInfo(
        userId: widget.user.uid,
        studentCode: studentCode?.isNotEmpty == true ? studentCode : null,
        career: career?.isNotEmpty == true ? career : null,
      );

      // Actualizar el estado local
      setState(() {
        if (studentCode?.isNotEmpty == true) _studentCode = studentCode;
        if (career?.isNotEmpty == true) _career = career;
      });

      _showSuccessSnackBar('¡Perfecto! Tu información académica ha sido actualizada');
    } catch (e) {
      _showErrorSnackBar('Hubo un problema al guardar los cambios. Inténtalo nuevamente');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _isLoading ? null : _saveProfile,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Header con foto de perfil
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    
                    // Información básica
                    _buildSectionCard(
                      title: 'Información Básica',
                      icon: Icons.person,
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
                                  initialValue: _studentCode ?? 'No especificado',
                                  enabled: false,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Color(0xFF1E3A8A)),
                                onPressed: () => _showEditStudentInfoDialog(),
                                tooltip: 'Editar información académica',
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
                    
                    // Información de contacto
                    _buildSectionCard(
                      title: 'Información de Contacto',
                      icon: Icons.contact_phone,
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
                    
                    // Contacto de emergencia
                    _buildSectionCard(
                      title: 'Contacto de Emergencia',
                      icon: Icons.emergency,
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
                    
                    // Estadísticas
                    _buildStatisticsSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Botones de acción
                    if (_isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _isEditing = false);
                                _loadUserProfile(); // Recargar datos originales
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                                side: BorderSide(color: Colors.grey[400]!),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Guardar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
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
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: widget.user.photoURL.isNotEmpty
                ? NetworkImage(widget.user.photoURL)
                : null,
            backgroundColor: Colors.white,
            child: widget.user.photoURL.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 50,
                    color: Color(0xFF1E3A8A),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            widget.user.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getRoleDisplayName(widget.user.role),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
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
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF1E3A8A),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: enabled ? const Color(0xFF1E3A8A) : Colors.grey[600],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[100],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadUserStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSectionCard(
            title: 'Estadísticas',
            icon: Icons.analytics,
            children: [
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          );
        }

        final stats = snapshot.data ?? {};

        return _buildSectionCard(
          title: 'Estadísticas',
          icon: Icons.analytics,
          children: [
            _buildStatItem(
              'Horas confirmadas',
              '${(stats['totalHours'] ?? 0.0).toStringAsFixed(1)} hrs',
              Icons.access_time,
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Actividades participadas',
              '${stats['totalActivities'] ?? 0}',
              Icons.event,
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Certificados obtenidos',
              '${stats['totalCertificates'] ?? 0}',
              Icons.card_membership,
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Actividades pendientes',
              '${stats['pendingActivities'] ?? 0}',
              Icons.pending,
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Tasa de confirmación',
              '${((stats['confirmationRate'] ?? 0.0) * 100).toStringAsFixed(1)}%',
              Icons.trending_up,
            ),
          ],
        );
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF1E3A8A),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
      ],
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