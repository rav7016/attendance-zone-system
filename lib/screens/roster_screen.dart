import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../models/attendance_event.dart';
import '../services/database_service.dart';

class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getCurrentlyPresent(int zoneId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final todayEvents =
        _db
            .getEventsByZone(zoneId)
            .where((event) => event.timestampUtc.isAfter(startOfDay.toUtc()))
            .toList()
          ..sort((a, b) => a.timestampUtc.compareTo(b.timestampUtc));

    final presentPeople = <int, Map<String, dynamic>>{};

    for (final event in todayEvents) {
      if (event.personId != null) {
        final person = _db.getPerson(event.personId!);
        if (person != null) {
          if (event.isAllow) {
            presentPeople[event.personId!] = {
              'person': person,
              'checkInTime': event.timestampUtc,
              'cardUid': event.cardUid,
            };
          } else if (event.reasonCode != ReasonCode.antiPassback) {
            // Remove from present list if denied (except anti-passback)
            presentPeople.remove(event.personId!);
          }
        }
      }
    }

    return presentPeople.values.toList()
      ..sort((a, b) => a['person'].fullName.compareTo(b['person'].fullName));
  }

  List<AttendanceEvent> _getRecentActivity(int zoneId) {
    final cutoff = DateTime.now().subtract(const Duration(hours: 8));
    return _db
        .getEventsByZone(zoneId)
        .where((event) => event.timestampUtc.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.timestampUtc.compareTo(a.timestampUtc));
  }

  Map<String, dynamic> _getZoneStatistics(int zoneId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final todayEvents = _db
        .getEventsByZone(zoneId)
        .where((event) => event.timestampUtc.isAfter(startOfDay.toUtc()))
        .toList();

    final allowedEvents = todayEvents.where((e) => e.isAllow).length;
    final deniedEvents = todayEvents.where((e) => e.isDeny).length;
    final totalEvents = todayEvents.length;

    final denialReasons = <ReasonCode, int>{};
    for (final event in todayEvents.where((e) => e.isDeny)) {
      denialReasons[event.reasonCode] =
          (denialReasons[event.reasonCode] ?? 0) + 1;
    }

    final uniqueVisitors = todayEvents
        .where((e) => e.isAllow && e.personId != null)
        .map((e) => e.personId!)
        .toSet()
        .length;

    return {
      'totalEvents': totalEvents,
      'allowedEvents': allowedEvents,
      'deniedEvents': deniedEvents,
      'uniqueVisitors': uniqueVisitors,
      'successRate': totalEvents > 0
          ? (allowedEvents / totalEvents * 100).toStringAsFixed(1)
          : '0.0',
      'denialReasons': denialReasons,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        if (!appState.isConfigured) {
          return const Center(child: Text('Device not configured'));
        }

        final zoneId = appState.currentZone!.zoneId;
        final currentlyPresent = _getCurrentlyPresent(zoneId);
        final recentActivity = _getRecentActivity(zoneId);
        final statistics = _getZoneStatistics(zoneId);

        return Column(
          children: [
            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.people), text: 'Present'),
                Tab(icon: Icon(Icons.history), text: 'Activity'),
                Tab(icon: Icon(Icons.analytics), text: 'Stats'),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Currently Present Tab
                  _buildPresentTab(currentlyPresent),

                  // Recent Activity Tab
                  _buildActivityTab(recentActivity),

                  // Statistics Tab
                  _buildStatisticsTab(statistics),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPresentTab(List<Map<String, dynamic>> presentPeople) {
    if (presentPeople.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No one currently present',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'People who check in will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Currently Present (${presentPeople.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  Provider.of<AppStateProvider>(
                    context,
                    listen: false,
                  ).refresh();
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            itemCount: presentPeople.length,
            itemBuilder: (context, index) {
              final data = presentPeople[index];
              final person = data['person'];
              final checkInTime = data['checkInTime'] as DateTime;
              final cardUid = data['cardUid'] as String;

              final duration = DateTime.now().difference(checkInTime);
              final durationText = _formatDuration(duration);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(
                      person.fullName
                          .split(' ')
                          .map((n) => n[0])
                          .take(2)
                          .join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    person.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (person.company != null) Text(person.company!),
                      Text(
                        'Card: $cardUid',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(checkInTime.toLocal()),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        durationText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTab(List<AttendanceEvent> recentActivity) {
    if (recentActivity.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No recent activity',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity (${recentActivity.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  Provider.of<AppStateProvider>(
                    context,
                    listen: false,
                  ).refresh();
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            itemCount: recentActivity.length,
            itemBuilder: (context, index) {
              final event = recentActivity[index];
              final person = event.personId != null
                  ? _db.getPerson(event.personId!)
                  : null;

              final isAllow = event.isAllow;
              final color = isAllow ? Colors.green : Colors.red;
              final icon = isAllow ? Icons.check_circle : Icons.cancel;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(
                    person?.fullName ?? 'Unknown User',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Card: ${event.cardUid}'),
                      Text(
                        event.reasonMessage,
                        style: TextStyle(color: color, fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat(
                          'HH:mm:ss',
                        ).format(event.timestampUtc.toLocal()),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (event.offlineFlag)
                        const Text(
                          'OFFLINE',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab(Map<String, dynamic> statistics) {
    final denialReasons = statistics['denialReasons'] as Map<ReasonCode, int>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today\'s Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCard(
                        title: 'Total Events',
                        value: '${statistics['totalEvents']}',
                        color: Colors.blue,
                      ),
                      _StatCard(
                        title: 'Allowed',
                        value: '${statistics['allowedEvents']}',
                        color: Colors.green,
                      ),
                      _StatCard(
                        title: 'Denied',
                        value: '${statistics['deniedEvents']}',
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCard(
                        title: 'Unique Visitors',
                        value: '${statistics['uniqueVisitors']}',
                        color: Colors.purple,
                      ),
                      _StatCard(
                        title: 'Success Rate',
                        value: '${statistics['successRate']}%',
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Denial Reasons
          if (denialReasons.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Denial Reasons',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...denialReasons.entries.map((entry) {
                      final reason = entry.key.toString().split('.').last;
                      final count = entry.value;
                      final percentage = statistics['deniedEvents'] > 0
                          ? (count / statistics['deniedEvents'] * 100)
                                .toStringAsFixed(1)
                          : '0.0';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _formatReasonCode(reason),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              '$count ($percentage%)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  String _formatReasonCode(String reason) {
    switch (reason) {
      case 'unknownCard':
        return 'Unknown Card';
      case 'inactiveCard':
        return 'Inactive Card';
      case 'wrongZone':
        return 'Wrong Zone';
      case 'outOfWindow':
        return 'Out of Time Window';
      case 'antiPassback':
        return 'Anti-Passback';
      case 'cardReadError':
        return 'Card Read Error';
      case 'deviceUnauthorized':
        return 'Device Unauthorized';
      case 'snapshotExpired':
        return 'Authorization Expired';
      default:
        return reason;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

