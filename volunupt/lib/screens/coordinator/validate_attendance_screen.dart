import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_dialogs.dart';
import '../../utils/feedback_overlay.dart';

class ValidateAttendanceScreen extends StatefulWidget {
  final UserModel user;

  const ValidateAttendanceScreen({
    super.key,
    required this.user,
  });

  @override
  State<ValidateAttendanceScreen> createState() => _ValidateAttendanceScreenState();
}

class _ValidateAttendanceScreenState extends State<ValidateAttendanceScreen> {
  String _selectedFilter = 'pending';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Validar Asistencias',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _buildAttendanceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Buscar por estudiante o actividad...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('pending', 'Pendientes', Icons.schedule),
                const SizedBox(width: 8),
                _buildFilterChip('confirmed', 'Confirmadas', Icons.check_circle),
                const SizedBox(width: 8),
                _buildFilterChip('rejected', 'Rechazadas', Icons.cancel),
                const SizedBox(width: 8),
                _buildFilterChip('all', 'Todas', Icons.list),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedFilter = value),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.primary,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildAttendanceList() {
    return StreamBuilder<List<AttendanceRecordModel>>(
      stream: AttendanceService.getAttendanceForValidation(
        coordinatorId: widget.user.uid,
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        if (snapshot.hasError) {
          // Tratar el error como estado vacío para evitar mostrar detalles técnicos
          return _buildEmptyState();
        }

        final allAttendances = snapshot.data ?? [];
        final filteredAttendances = _filterAttendances(allAttendances);

        if (filteredAttendances.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredAttendances.length,
            itemBuilder: (context, index) {
              return _buildAttendanceCard(filteredAttendances[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildAttendanceCard(AttendanceRecordModel attendance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estudiante y estado
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    attendance.userId.isNotEmpty 
                        ? attendance.userId[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estudiante (ID): ${attendance.userId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Registro: ${attendance.sessionId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(attendance.status),
              ],
            ),
            const SizedBox(height: 16),
            
            // Información de la actividad
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actividad (ID): ${attendance.subEventId}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Evento (ID): ${attendance.baseEventId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(attendance.checkInTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Check-in: ${_formatTime(attendance.checkInTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Horas calculadas
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Horas confirmadas: ${attendance.hoursEarned.toStringAsFixed(1)}h',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            
            if ((attendance.coordinatorNotes ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        attendance.coordinatorNotes ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Botones de acción
            if (attendance.status == AttendanceStatus.checkedIn) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(attendance),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showConfirmDialog(attendance),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Confirmar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (attendance.status == AttendanceStatus.validated || attendance.status == AttendanceStatus.absent) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showEditDialog(attendance),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(AttendanceStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case AttendanceStatus.checkedIn:
        color = AppColors.primary;
        text = 'Pendiente';
        icon = Icons.schedule;
        break;
      case AttendanceStatus.validated:
        color = AppColors.success;
        text = 'Confirmada';
        icon = Icons.check_circle;
        break;
      case AttendanceStatus.absent:
        color = AppColors.error;
        text = 'Rechazada';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_selectedFilter) {
      case 'pending':
        message = 'No hay asistencias pendientes de validación';
        icon = Icons.schedule;
        break;
      case 'confirmed':
        message = 'No hay asistencias confirmadas';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        message = 'No hay asistencias rechazadas';
        icon = Icons.cancel;
        break;
      default:
        message = 'No se encontraron asistencias';
        icon = Icons.list;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Intenta con otros términos de búsqueda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  

  List<AttendanceRecordModel> _filterAttendances(List<AttendanceRecordModel> attendances) {
    if (_searchQuery.isEmpty) return attendances;

    return attendances.where((attendance) {
      final query = _searchQuery.toLowerCase();
      return attendance.userId.toLowerCase().contains(query) ||
             attendance.subEventId.toLowerCase().contains(query) ||
             attendance.baseEventId.toLowerCase().contains(query);
    }).toList();
  }

void _showConfirmDialog(AttendanceRecordModel attendance) {
  final hoursController = TextEditingController(
      text: attendance.hoursEarned.toStringAsFixed(1),
  );
  final notesController = TextEditingController(text: attendance.coordinatorNotes ?? '');

  AppDialogs.modal(
    context,
    title: 'Confirmar Asistencia',
    icon: Icons.check_circle,
    iconColor: AppColors.success,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Estudiante (ID): ${attendance.userId}'),
        Text('Actividad (ID): ${attendance.subEventId}'),
        const SizedBox(height: 16),
        TextField(
          controller: hoursController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Horas confirmadas',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notas (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    ),
    actions: [
      AppDialogs.cancelAction(onPressed: () => Navigator.of(context).pop()),
      AppDialogs.primaryAction(
        label: 'Confirmar',
        onPressed: () async {
          Navigator.of(context).pop();
          await _confirmAttendance(
            attendance,
            double.tryParse(hoursController.text) ?? attendance.hoursEarned,
            notesController.text,
          );
        },
      ),
    ],
  );
}

void _showRejectDialog(AttendanceRecordModel attendance) {
  final notesController = TextEditingController();

  AppDialogs.modal(
    context,
    title: 'Rechazar Asistencia',
    icon: Icons.error_outline,
    iconColor: AppColors.error,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Estudiante (ID): ${attendance.userId}'),
        Text('Actividad (ID): ${attendance.subEventId}'),
        const SizedBox(height: 16),
        TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motivo del rechazo',
            border: OutlineInputBorder(),
            hintText: 'Explica por qué se rechaza esta asistencia...',
          ),
        ),
      ],
    ),
    actions: [
      AppDialogs.cancelAction(onPressed: () => Navigator.of(context).pop()),
      AppDialogs.dangerAction(
        label: 'Rechazar',
        onPressed: () async {
          if (notesController.text.trim().isEmpty) {
            FeedbackOverlay.showError(context, 'Debes proporcionar un motivo para el rechazo');
            return;
          }
          Navigator.of(context).pop();
          await _rejectAttendance(attendance, notesController.text);
        },
      ),
    ],
  );
}

  void _showEditDialog(AttendanceRecordModel attendance) {
    final hoursController = TextEditingController(
      text: attendance.hoursEarned.toStringAsFixed(1),
    );
    final notesController = TextEditingController(text: '');

    AppDialogs.modal(
      context,
      title: 'Editar Asistencia',
      icon: Icons.edit,
      iconColor: AppColors.primary,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estudiante (ID): ${attendance.userId}'),
          Text('Actividad (ID): ${attendance.subEventId}'),
          Text('Estado actual: ${attendance.status == AttendanceStatus.validated ? 'Validada' : attendance.status == AttendanceStatus.absent ? 'Rechazada' : 'Registrada'}'),
          const SizedBox(height: 16),
          TextField(
            controller: hoursController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Horas confirmadas',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notas',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        AppDialogs.cancelAction(onPressed: () => Navigator.of(context).pop()),
        AppDialogs.primaryAction(
          label: 'Actualizar',
          onPressed: () async {
            Navigator.of(context).pop();
            await _updateAttendance(
              attendance,
              double.tryParse(hoursController.text) ?? attendance.hoursEarned,
              notesController.text,
            );
          },
        ),
      ],
    );
  }

  Future<void> _confirmAttendance(AttendanceRecordModel attendance, double hours, String notes) async {
    try {
      await AttendanceService.validateAttendance(
        recordId: attendance.recordId,
        hoursEarned: hours,
        coordinatorId: widget.user.uid,
        notes: notes,
      );
      if (mounted) {
        await FeedbackOverlay.showSuccess(context, 'Asistencia confirmada exitosamente');
      }
    } catch (e) {
      if (mounted) {
        await FeedbackOverlay.showError(context, 'No se pudo confirmar la asistencia');
      }
    }
  }

  Future<void> _rejectAttendance(AttendanceRecordModel attendance, String notes) async {
    try {
      await AttendanceService.rejectAttendance(
        recordId: attendance.recordId,
        coordinatorId: widget.user.uid,
        reason: notes,
      );
      if (mounted) {
        await FeedbackOverlay.showInfo(context, 'Asistencia rechazada');
      }
    } catch (e) {
      if (mounted) {
        await FeedbackOverlay.showError(context, 'No se pudo rechazar la asistencia');
      }
    }
  }

  Future<void> _updateAttendance(AttendanceRecordModel attendance, double hours, String notes) async {
    try {
      await AttendanceService.validateAttendance(
        recordId: attendance.recordId,
        hoursEarned: hours,
        coordinatorId: widget.user.uid,
        notes: notes,
      );
      if (mounted) {
        await FeedbackOverlay.showSuccess(context, 'Asistencia actualizada exitosamente');
      }
    } catch (e) {
      if (mounted) {
        await FeedbackOverlay.showError(context, 'No se pudo actualizar la asistencia');
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}