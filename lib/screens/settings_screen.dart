import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../services/database_service.dart';
import '../services/card_scanner_service.dart';
import '../services/access_decision_engine.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'constituency_screen.dart';
import 'user_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _db = DatabaseService.instance;
  final AccessDecisionEngine _decisionEngine = AccessDecisionEngine();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Information
              _buildDeviceInfoCard(appState),

              const SizedBox(height: 16),

              // Scanner Capabilities
              _buildScannerCapabilitiesCard(),

              const SizedBox(height: 16),

              // Database Statistics
              _buildDatabaseStatsCard(),

              const SizedBox(height: 16),

              // Actions
              _buildActionsCard(appState),

              const SizedBox(height: 16),

              // System Information
              _buildSystemInfoCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeviceInfoCard(AppStateProvider appState) {
    final reader = appState.currentReader;
    final zone = appState.currentZone;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.device_hub, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Device Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _InfoRow(
              label: 'Reader ID',
              value: reader?.readerId ?? 'Not configured',
            ),
            _InfoRow(label: 'Zone', value: zone?.zoneName ?? 'Not assigned'),
            _InfoRow(
              label: 'Location',
              value: zone?.location ?? 'Not specified',
            ),
            _InfoRow(
              label: 'Device Type',
              value: reader?.deviceType ?? 'Unknown',
            ),
            _InfoRow(
              label: 'Status',
              value: appState.isOnline ? 'Online' : 'Offline',
              valueColor: appState.isOnline ? Colors.green : Colors.orange,
            ),
            _InfoRow(
              label: 'Last Seen',
              value: reader?.lastSeen != null
                  ? DateFormat(
                      'yyyy-MM-dd HH:mm:ss',
                    ).format(reader!.lastSeen!.toLocal())
                  : 'Never',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerCapabilitiesCard() {
    final capabilities = CardScannerService.instance.getCapabilities();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.scanner, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Scanner Capabilities',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ...capabilities.entries.map((entry) {
              final capability = entry.key.toUpperCase();
              final isAvailable = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(capability),
                    Row(
                      children: [
                        Icon(
                          isAvailable ? Icons.check_circle : Icons.cancel,
                          color: isAvailable ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAvailable ? 'Available' : 'Not Available',
                          style: TextStyle(
                            color: isAvailable ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildDatabaseStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.storage, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Database Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _InfoRow(label: 'Total Persons', value: '${_db.totalPersons}'),
            _InfoRow(label: 'Total Cards', value: '${_db.totalCards}'),
            _InfoRow(label: 'Total Zones', value: '${_db.totalZones}'),
            _InfoRow(label: 'Total Readers', value: '${_db.totalReaders}'),
            _InfoRow(label: 'Total Events', value: '${_db.totalEvents}'),
            _InfoRow(
              label: 'Constituencies',
              value: '${_db.totalConstituencies}',
            ),
            _InfoRow(label: 'Users', value: '${_db.totalUsers}'),
            _InfoRow(
              label: 'Unsynced Events',
              value: '${_db.unsyncedEventCount}',
              valueColor: _db.unsyncedEventCount > 0
                  ? Colors.orange
                  : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(AppStateProvider appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Refresh Data
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await appState.refresh();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data refreshed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Data'),
              ),
            ),

            const SizedBox(height: 8),

            // View Constituencies
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ConstituencyScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.location_city),
                label: const Text('View Constituencies'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
            ),

            const SizedBox(height: 16),

            // User Management - ALWAYS VISIBLE FOR TESTING
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const UserManagementScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.people),
                label: const Text('🔥 MANAGE USERS 🔥'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (AuthService.instance.currentUser?.isAdmin == true)
              const SizedBox(height: 8),

            // Logout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true) {
                    await AuthService.instance.logout();
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),

            const SizedBox(height: 8),

            // Test Database Persistence
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Add a test user to demonstrate persistence
                  final testUser = User(
                    userId: 'test-${DateTime.now().millisecondsSinceEpoch}',
                    username: 'testuser',
                    email: 'test@example.com',
                    passwordHash: 'test123',
                    fullName: 'Test User ${DateTime.now().minute}',
                    role: UserRole.viewer,
                    assignedConstituencies: [1, 2, 3],
                  );

                  await DatabaseService.instance.saveUser(testUser);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Test user created: ${testUser.fullName}\nTotal users: ${DatabaseService.instance.totalUsers}',
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.science),
                label: const Text('Test Database Persistence'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ),

            const SizedBox(height: 8),

            // Clear Anti-Passback Cache
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _decisionEngine.clearAntiPassbackCache();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Anti-passback cache cleared'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Anti-Passback Cache'),
              ),
            ),

            const SizedBox(height: 8),

            // Toggle Online/Offline (for testing)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  appState.setOnlineStatus(!appState.isOnline);
                },
                icon: Icon(appState.isOnline ? Icons.wifi_off : Icons.wifi),
                label: Text(appState.isOnline ? 'Go Offline' : 'Go Online'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appState.isOnline
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Danger Zone
            const Divider(),
            const Text(
              'Danger Zone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),

            // Clear All Data
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showClearDataDialog(),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Clear All Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'System Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const _InfoRow(label: 'App Version', value: '1.0.0'),
            const _InfoRow(label: 'Build Number', value: '1'),
            _InfoRow(
              label: 'Current Time',
              value: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
            ),
            _InfoRow(
              label: 'UTC Time',
              value: DateFormat(
                'yyyy-MM-dd HH:mm:ss',
              ).format(DateTime.now().toUtc()),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Clear All Data'),
          ],
        ),
        content: const Text(
          'This will permanently delete all stored data including:\n\n'
          '• All persons and cards\n'
          '• All attendance events\n'
          '• All zones and readers\n'
          '• Authorization snapshots\n\n'
          'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      await _db.clearAllData();

      // Reset app state
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      appState.setOnlineStatus(false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, color: valueColor),
          ),
        ],
      ),
    );
  }
}
