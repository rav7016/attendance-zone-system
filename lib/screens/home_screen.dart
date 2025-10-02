import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../services/card_scanner_service.dart';
import '../services/access_decision_engine.dart';
import '../services/database_service.dart';
import '../models/zone.dart';
import '../models/person.dart';
import '../models/card.dart' as card_model;
import '../models/auth_snapshot.dart';
import 'scan_screen.dart';
import 'setup_screen.dart';
import 'roster_screen.dart';
import 'settings_screen.dart';
import 'user_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final AccessDecisionEngine _decisionEngine = AccessDecisionEngine();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    // Check if reader is configured
    // For demo purposes, create a default setup if none exists
    if (!appState.isConfigured) {
      await _createDemoSetup(appState);
    }

    // Listen to scan results
    CardScannerService.instance.scanStream.listen(_handleScanResult);
  }

  Future<void> _createDemoSetup(AppStateProvider appState) async {
    // This creates a demo setup for testing
    // In production, this would be done through proper onboarding

    try {
      // Create demo zones
      final zones = [
        {
          'id': 1,
          'name': 'Main Hall',
          'location': 'Building A',
          'capacity': 100,
        },
        {
          'id': 2,
          'name': 'Conference Room A',
          'location': 'Building A',
          'capacity': 50,
        },
        {
          'id': 3,
          'name': 'Conference Room B',
          'location': 'Building B',
          'capacity': 30,
        },
      ];

      for (final zoneData in zones) {
        final zone = Zone(
          zoneId: zoneData['id'] as int,
          zoneName: zoneData['name'] as String,
          location: zoneData['location'] as String,
          capacity: zoneData['capacity'] as int,
        );
        await DatabaseService.instance.saveZone(zone);
      }

      // Create demo reader for Main Hall
      await appState.createReader(
        readerId: 'READER-001',
        zoneId: 1,
        deviceType: 'Mobile Scanner',
      );

      // Create demo people and cards
      await _createDemoData();
    } catch (e) {
      // Error creating demo setup - silently continue
    }
  }

  Future<void> _createDemoData() async {
    final db = DatabaseService.instance;

    // Demo people
    final demoPersons = [
      {'id': 1, 'name': 'John Doe', 'zone': 1, 'company': 'Tech Corp'},
      {'id': 2, 'name': 'Jane Smith', 'zone': 1, 'company': 'Design Inc'},
      {'id': 3, 'name': 'Bob Johnson', 'zone': 2, 'company': 'Marketing Ltd'},
      {'id': 4, 'name': 'Alice Brown', 'zone': 3, 'company': 'Sales Co'},
    ];

    for (final personData in demoPersons) {
      final person = Person(
        personId: personData['id'] as int,
        fullName: personData['name'] as String,
        primaryZoneId: personData['zone'] as int,
        company: personData['company'] as String,
      );
      await db.savePerson(person);

      // Create corresponding card
      final card = card_model.Card(
        cardUid: 'CARD-${(personData['id'] as int).toString().padLeft(3, '0')}',
        personId: personData['id'] as int,
        cardType: card_model.CardType.hybrid,
        state: card_model.CardState.active,
      );
      await db.saveCard(card);

      // Create snapshot item
      final snapshotItem = AuthSnapshotItem(
        cardUid: card.cardUid,
        personId: person.personId,
        personName: person.fullName,
        primaryZoneId: person.primaryZoneId,
        cardState: 'active',
      );
      await DatabaseService.instance.saveSnapshotItem(
        snapshotItem.cardUid,
        snapshotItem,
      );
    }
  }

  void _handleScanResult(ScanResult scanResult) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    if (!appState.isConfigured) return;

    // Make access decision
    final decision = await _decisionEngine.makeDecision(
      cardUid: scanResult.cardUid,
      readerId: appState.currentReader!.readerId,
      isOnline: appState.isOnline,
    );

    // Create attendance event
    final event = await _decisionEngine.createAttendanceEvent(
      cardUid: scanResult.cardUid,
      readerId: appState.currentReader!.readerId,
      result: decision,
      isOffline: !appState.isOnline,
    );

    // Add to app state
    await appState.addEvent(event);

    // Show result
    if (mounted) {
      _showScanResult(decision, scanResult);
    }
  }

  void _showScanResult(AccessDecisionResult decision, ScanResult scanResult) {
    final color = decision.isAllow ? Colors.green : Colors.red;
    final icon = decision.isAllow ? Icons.check_circle : Icons.cancel;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: color.withOpacity(0.1),
        title: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Text(
              decision.isAllow ? 'ACCESS GRANTED' : 'ACCESS DENIED',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Card: ${scanResult.cardUid}'),
            if (decision.personName != null)
              Text('Name: ${decision.personName}'),
            const SizedBox(height: 8),
            Text(
              decision.message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scanned via: ${scanResult.scanMode.toString().split('.').last.toUpperCase()}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        if (!appState.isConfigured) {
          return const SetupScreen();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(appState.currentZone?.zoneName ?? 'Attendance System'),
            actions: [
              // User Management Button - ALWAYS VISIBLE
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UserManagementScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.people, size: 16),
                  label: const Text('USERS', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ),
              // Online/Offline indicator
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      appState.isOnline ? Icons.wifi : Icons.wifi_off,
                      color: appState.isOnline ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      appState.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: appState.isOnline ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: const [ScanScreen(), RosterScreen(), SettingsScreen()],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner),
                label: 'Scan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Roster',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
