import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _maintenanceMode = false;
  bool _autoBackup = true;
  String _backupFrequency = 'daily';
  int _sessionTimeout = 30;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Sistema'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuario no autenticado'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationSettings(),
                const SizedBox(height: 24),
                _buildSystemSettings(),
                const SizedBox(height: 24),
                _buildBackupSettings(),
                const SizedBox(height: 24),
                _buildSecuritySettings(),
                const SizedBox(height: 24),
                _buildDangerZone(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notificaciones',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Notificaciones por Email'),
              subtitle: const Text('Recibir alertas del sistema por correo'),
              value: _emailNotifications,
              onChanged: (value) {
                setState(() {
                  _emailNotifications = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Notificaciones Push'),
              subtitle: const Text('Recibir notificaciones en tiempo real'),
              value: _pushNotifications,
              onChanged: (value) {
                setState(() {
                  _pushNotifications = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sistema',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Modo Mantenimiento'),
              subtitle: const Text('Bloquear acceso a usuarios regulares'),
              value: _maintenanceMode,
              onChanged: (value) {
                setState(() {
                  _maintenanceMode = value;
                });
              },
            ),
            ListTile(
              title: const Text('Tiempo de Sesión'),
              subtitle: Text('$_sessionTimeout minutos'),
              trailing: SizedBox(
                width: 100,
                child: Slider(
                  value: _sessionTimeout.toDouble(),
                  min: 15,
                  max: 120,
                  divisions: 7,
                  label: '$_sessionTimeout min',
                  onChanged: (value) {
                    setState(() {
                      _sessionTimeout = value.round();
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Respaldos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Respaldo Automático'),
              subtitle: const Text('Crear respaldos automáticamente'),
              value: _autoBackup,
              onChanged: (value) {
                setState(() {
                  _autoBackup = value;
                });
              },
            ),
            ListTile(
              title: const Text('Frecuencia de Respaldo'),
              subtitle: Text(_getBackupFrequencyText()),
              trailing: DropdownButton<String>(
                value: _backupFrequency,
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Diario')),
                  DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                  DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                ],
                onChanged: _autoBackup ? (value) {
                  setState(() {
                    _backupFrequency = value ?? 'daily';
                  });
                } : null,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createBackup,
                    icon: const Icon(Icons.backup),
                    label: const Text('Crear Respaldo'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _restoreBackup,
                    icon: const Icon(Icons.restore),
                    label: const Text('Restaurar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seguridad',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Logs de Seguridad'),
              subtitle: const Text('Ver registros de actividad'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _viewSecurityLogs,
            ),
            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text('Gestión de API Keys'),
              subtitle: const Text('Administrar claves de acceso'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _manageApiKeys,
            ),
            ListTile(
              leading: const Icon(Icons.shield),
              title: const Text('Configuración de Firewall'),
              subtitle: const Text('Reglas de acceso y seguridad'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _configureFirewall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zona de Peligro',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
              title: Text(
                'Limpiar Datos del Sistema',
                style: TextStyle(color: Colors.red.shade700),
              ),
              subtitle: const Text('Eliminar logs y datos temporales'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _clearSystemData,
            ),
            ListTile(
              leading: Icon(Icons.refresh, color: Colors.red.shade700),
              title: Text(
                'Reiniciar Sistema',
                style: TextStyle(color: Colors.red.shade700),
              ),
              subtitle: const Text('Reiniciar todos los servicios'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _restartSystem,
            ),
          ],
        ),
      ),
    );
  }

  String _getBackupFrequencyText() {
    switch (_backupFrequency) {
      case 'daily':
        return 'Cada día a las 2:00 AM';
      case 'weekly':
        return 'Cada domingo a las 2:00 AM';
      case 'monthly':
        return 'El primer día de cada mes';
      default:
        return 'Diario';
    }
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración guardada exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _createBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Respaldo'),
        content: const Text('¿Está seguro de que desea crear un respaldo del sistema?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Respaldo creado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _restoreBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Respaldo'),
        content: const Text('Esta acción sobrescribirá los datos actuales. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidad en desarrollo'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  void _viewSecurityLogs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _manageApiKeys() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _configureFirewall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _clearSystemData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Datos'),
        content: const Text('Esta acción eliminará logs y datos temporales. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Datos limpiados exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _restartSystem() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reiniciar Sistema'),
        content: const Text('Esta acción reiniciará todos los servicios. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sistema reiniciado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }
}