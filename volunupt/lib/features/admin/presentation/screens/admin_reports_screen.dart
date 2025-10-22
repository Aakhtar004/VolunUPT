import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/admin_providers.dart' hide adminStatsProvider;
import '../providers/admin_stats_providers.dart';
import '../../domain/entities/admin_stats_entity.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _selectedDateRange;
  String _selectedPeriod = 'Último mes';
  String _selectedGrowthMetric = 'Usuarios';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;

    if (currentUser == null || currentUser.role != 'gestor_rsu') {
      return _buildUnauthorizedState(context);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildDateRangeSelector(context),
                const SizedBox(height: 24),
                _buildTabView(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthorizedState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso Denegado'),
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Acceso Restringido',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Solo los gestores RSU pueden ver reportes',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Reportes y Analíticas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: const Center(
            child: Icon(Icons.analytics, size: 60, color: Colors.white),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _showExportDialog(context),
          icon: const Icon(Icons.download),
          tooltip: 'Exportar reportes',
        ),
        IconButton(
          onPressed: () => _refreshData(),
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar datos',
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Período de Análisis',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: InputDecoration(
                      labelText: 'Período predefinido',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Última semana',
                        child: Text('Última semana'),
                      ),
                      DropdownMenuItem(
                        value: 'Último mes',
                        child: Text('Último mes'),
                      ),
                      DropdownMenuItem(
                        value: 'Últimos 3 meses',
                        child: Text('Últimos 3 meses'),
                      ),
                      DropdownMenuItem(
                        value: 'Último año',
                        child: Text('Último año'),
                      ),
                      DropdownMenuItem(
                        value: 'Personalizado',
                        child: Text('Personalizado'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value ?? 'Último mes';
                        _updateDateRangeFromPeriod();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectCustomDateRange(context),
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _selectedDateRange == null
                          ? 'Seleccionar fechas'
                          : '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabView(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'General', icon: Icon(Icons.dashboard)),
              Tab(text: 'Usuarios', icon: Icon(Icons.people)),
              Tab(text: 'Eventos', icon: Icon(Icons.event)),
              Tab(text: 'Participación', icon: Icon(Icons.trending_up)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralReports(context),
                _buildUserReports(context),
                _buildEventReports(context),
                _buildParticipationReports(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralReports(BuildContext context) {
    final dateRange = DateTimeRange(
      start: _selectedDateRange!.start,
      end: _selectedDateRange!.end,
    );
    final adminStatsAsync = ref.watch(adminStatsProvider(dateRange));

    return adminStatsAsync.when(
      data: (stats) => SingleChildScrollView(
        child: Column(
          children: [
            _buildOverviewCards(context, stats),
            const SizedBox(height: 24),
            _buildGrowthChart(context, stats),
            const SizedBox(height: 24),
            _buildTopMetrics(context, stats),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildUserReports(BuildContext context) {
    final dateRange = DateTimeRange(
      start: _selectedDateRange!.start,
      end: _selectedDateRange!.end,
    );
    final adminStatsAsync = ref.watch(adminStatsProvider(dateRange));

    return adminStatsAsync.when(
      data: (stats) => SingleChildScrollView(
        child: Column(
          children: [
            _buildUserStatsCards(context, stats),
            const SizedBox(height: 24),
            _buildUserDistributionChart(context),
            const SizedBox(height: 24),
            _buildActiveUsersChart(context),
            const SizedBox(height: 24),
            _buildTopVolunteers(context),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildEventReports(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildEventStatsCards(context),
          const SizedBox(height: 24),
          _buildEventCategoriesChart(context),
          const SizedBox(height: 24),
          _buildEventSuccessRate(context),
          const SizedBox(height: 24),
          _buildPopularEvents(context),
        ],
      ),
    );
  }

  Widget _buildParticipationReports(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildParticipationStatsCards(context),
          const SizedBox(height: 24),
          _buildAttendanceChart(context),
          const SizedBox(height: 24),
          _buildVolunteerHoursChart(context),
          const SizedBox(height: 24),
          _buildEngagementMetrics(context),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, AdminStatsEntity stats) {
    final participationRate = stats.totalEvents > 0
        ? (stats.totalInscriptions / stats.totalEvents * 100).toStringAsFixed(1)
        : '0.0';

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Usuarios Totales',
            value: '${stats.totalUsers}',
            change: '+0%',
            isPositive: true,
            icon: Icons.people,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Eventos Activos',
            value: '${stats.activeEvents}',
            change: '+0%',
            isPositive: true,
            icon: Icons.event,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Total Inscripciones',
            value: '${stats.totalInscriptions}',
            change: '+0%',
            isPositive: true,
            icon: Icons.schedule,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Tasa Participación',
            value: '$participationRate%',
            change: '+0%',
            isPositive: true,
            icon: Icons.trending_up,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthChart(BuildContext context, AdminStatsEntity stats) {
    final base = _selectedGrowthMetric == 'Usuarios'
        ? stats.totalUsers.toDouble()
        : _selectedGrowthMetric == 'Eventos'
            ? stats.totalEvents.toDouble()
            : stats.totalInscriptions.toDouble();

    final months = List.generate(
      6,
      (i) => DateTime.now().subtract(Duration(days: 30 * (5 - i))),
    );
    final percents = [0.55, 0.6, 0.7, 0.8, 0.9, 1.0];
    final spots = List.generate(
      6,
      (i) => FlSpot(i.toDouble(), (base * percents[i])),
    );
    final maxY = (base * 1.1).clamp(1.0, double.infinity);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Crecimiento Mensual',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _selectedGrowthMetric,
                  items: const [
                    DropdownMenuItem(
                      value: 'Usuarios',
                      child: Text('Usuarios'),
                    ),
                    DropdownMenuItem(value: 'Eventos', child: Text('Eventos')),
                    DropdownMenuItem(
                      value: 'Inscripciones',
                      child: Text('Inscripciones'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedGrowthMetric = value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 5,
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx > 5) return const SizedBox.shrink();
                          final label = DateFormat('MMM', 'es').format(months[idx]);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(label.toUpperCase(),
                                style: Theme.of(context).textTheme.bodySmall),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString(),
                              style: Theme.of(context).textTheme.bodySmall);
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            Theme.of(context).colorScheme.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMetrics(BuildContext context, AdminStatsEntity stats) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eventos Más Populares',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (stats.popularEvents.isEmpty)
                    const Text('No hay eventos disponibles')
                  else
                    ...stats.popularEvents.take(3).toList().asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final event = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: [
                                  Colors.amber,
                                  Colors.grey,
                                  Colors.brown,
                                ][index],
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
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
                                      event.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${event.participantCount} participantes',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categorías Más Activas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (stats.categoryStats.isEmpty)
                    const Text('No hay categorías disponibles')
                  else
                    ...stats.categoryStats.take(3).toList().asMap().entries.map((
                      entry,
                    ) {
                      final index = entry.key;
                      final categoryData = entry.value;
                      final color = [
                        Colors.blue,
                        Colors.green,
                        Colors.red,
                        Colors.orange,
                        Colors.purple,
                      ][index % 5];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    categoryData.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${categoryData.percentage.toStringAsFixed(1)}%',
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: categoryData.percentage / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserStatsCards(BuildContext context, AdminStatsEntity stats) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Nuevos Usuarios',
            value: '${stats.newUsersThisMonth}',
            change: '+0%',
            isPositive: true,
            icon: Icons.person_add,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Usuarios Activos',
            value: '${stats.activeUsers}',
            change: '+0%',
            isPositive: true,
            icon: Icons.people,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Retención',
            value: '${stats.retentionRate.toStringAsFixed(1)}%',
            change: '+0%',
            isPositive: true,
            icon: Icons.trending_up,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildUserDistributionChart(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución de Usuarios por Rol',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Gráfico Circular\n(Implementar con fl_chart)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendItem(
                        color: Colors.blue,
                        label: 'Estudiantes',
                        value: '85%',
                      ),
                      _LegendItem(
                        color: Colors.orange,
                        label: 'Coordinadores',
                        value: '12%',
                      ),
                      _LegendItem(
                        color: Colors.purple,
                        label: 'Gestores RSU',
                        value: '3%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveUsersChart(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usuarios Activos por Día',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Gráfico de Líneas\n(Implementar con fl_chart)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopVolunteers(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Voluntarios del Período',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
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
                            'Voluntario ${index + 1}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${50 - (index * 8)} horas de voluntariado',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${15 - (index * 2)} eventos',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventStatsCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Eventos Creados',
            value: '28',
            change: '+12%',
            isPositive: true,
            icon: Icons.add_circle,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Eventos Completados',
            value: '22',
            change: '+8%',
            isPositive: true,
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Tasa de Éxito',
            value: '79%',
            change: '-3%',
            isPositive: false,
            icon: Icons.trending_down,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildEventCategoriesChart(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Eventos por Categoría',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Gráfico de Barras\n(Implementar con fl_chart)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventSuccessRate(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasa de Éxito por Categoría',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...[
              'Educación',
              'Medio Ambiente',
              'Salud',
              'Cultura',
              'Deportes',
            ].asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              final percentage = [85, 92, 78, 88, 75][index];
              final color = [
                Colors.blue,
                Colors.green,
                Colors.red,
                Colors.purple,
                Colors.orange,
              ][index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(category)),
                        Text(
                          '$percentage%',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularEvents(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Eventos Más Populares',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: [
                          Colors.blue,
                          Colors.green,
                          Colors.red,
                          Colors.purple,
                          Colors.orange,
                        ][index],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.event,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Evento Popular ${index + 1}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${150 - (index * 20)} inscripciones',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${95 - (index * 5)}%',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                        ),
                        Text(
                          'asistencia',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationStatsCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Total Inscripciones',
            value: '2,456',
            change: '+18%',
            isPositive: true,
            icon: Icons.how_to_reg,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Asistencias',
            value: '1,892',
            change: '+12%',
            isPositive: true,
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Tasa Asistencia',
            value: '77%',
            change: '-2%',
            isPositive: false,
            icon: Icons.trending_down,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceChart(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tendencia de Asistencia',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Gráfico de Área\n(Implementar con fl_chart)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerHoursChart(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horas de Voluntariado Acumuladas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Gráfico de Líneas Acumulativo\n(Implementar con fl_chart)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementMetrics(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métricas de Compromiso',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _EngagementMetric(
                    title: 'Promedio Eventos/Usuario',
                    value: '3.2',
                    icon: Icons.person,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EngagementMetric(
                    title: 'Tiempo Promedio/Evento',
                    value: '4.5h',
                    icon: Icons.schedule,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _EngagementMetric(
                    title: 'Usuarios Recurrentes',
                    value: '68%',
                    icon: Icons.repeat,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EngagementMetric(
                    title: 'Satisfacción Promedio',
                    value: '4.7/5',
                    icon: Icons.star,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar datos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _refreshData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateDateRangeFromPeriod() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Última semana':
        _selectedDateRange = DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
        break;
      case 'Último mes':
        _selectedDateRange = DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
        break;
      case 'Últimos 3 meses':
        _selectedDateRange = DateTimeRange(
          start: now.subtract(const Duration(days: 90)),
          end: now,
        );
        break;
      case 'Último año':
        _selectedDateRange = DateTimeRange(
          start: now.subtract(const Duration(days: 365)),
          end: now,
        );
        break;
    }
  }

  void _selectCustomDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedPeriod = 'Personalizado';
      });
    }
  }

  void _refreshData() {
    ref.invalidate(adminStatsProvider);
    ref.invalidate(recentActivityProvider);
    ref.invalidate(systemHealthProvider);
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Reportes'),
        content: const Text(
          'Se exportarán todos los reportes del período seleccionado en formato PDF. ¿Deseas continuar?',
        ),
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
                  content: Text(
                    'Exportación iniciada. Se descargará el archivo PDF.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: color),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withOpacity(
                      0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _EngagementMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _EngagementMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
