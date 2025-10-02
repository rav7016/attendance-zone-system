import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/zone.dart';
import '../services/database_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _readerIdController = TextEditingController();
  int? _selectedZoneId;
  bool _isLoading = false;
  List<Zone> _availableZones = [];

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  @override
  void dispose() {
    _readerIdController.dispose();
    super.dispose();
  }

  Future<void> _loadZones() async {
    final zones = DatabaseService.instance.getAllZones();
    setState(() {
      _availableZones = zones;
      if (zones.isNotEmpty) {
        _selectedZoneId = zones.first.zoneId;
      }
    });
  }

  Future<void> _setupReader() async {
    if (!_formKey.currentState!.validate() || _selectedZoneId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);

      await appState.createReader(
        readerId: _readerIdController.text.trim(),
        zoneId: _selectedZoneId!,
        deviceType: 'Mobile Scanner',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reader setup completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Setup'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.settings, size: 80, color: Colors.blue),
              const SizedBox(height: 24),

              const Text(
                'Welcome to Attendance System',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              const Text(
                'Please configure this device as a card reader for your assigned zone.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Reader ID Input
              TextFormField(
                controller: _readerIdController,
                decoration: const InputDecoration(
                  labelText: 'Reader ID',
                  hintText: 'e.g., READER-001',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code_scanner),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a Reader ID';
                  }
                  if (value.trim().length < 3) {
                    return 'Reader ID must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Zone Selection
              const Text(
                'Assigned Zone',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

              if (_availableZones.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.orange.withOpacity(0.1),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No zones available. Please contact your administrator.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<int>(
                  value: _selectedZoneId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  items: _availableZones.map((zone) {
                    return DropdownMenuItem<int>(
                      value: zone.zoneId,
                      child: Text(
                        zone.location != null
                            ? '${zone.zoneName} (${zone.location})'
                            : zone.zoneName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedZoneId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a zone';
                    }
                    return null;
                  },
                ),

              const SizedBox(height: 32),

              // Setup Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading || _availableZones.isEmpty
                      ? null
                      : _setupReader,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isLoading ? 'Setting up...' : 'Complete Setup'),
                ),
              ),

              const SizedBox(height: 24),

              // Info Card
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Setup Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Each device must have a unique Reader ID\n'
                        '• The device will be assigned to the selected zone\n'
                        '• Only cards authorized for this zone will be granted access\n'
                        '• The device can work offline with cached authorization data',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
