import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/app_state_provider.dart';
import '../services/card_scanner_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  MobileScannerController? mobileScannerController;
  final TextEditingController _manualController = TextEditingController();

  late TabController _tabController;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    mobileScannerController = MobileScannerController();
    CardScannerService.instance.setMobileScannerController(
      mobileScannerController!,
    );
  }

  @override
  void dispose() {
    mobileScannerController?.dispose();
    _manualController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    await CardScannerService.instance.toggleMobileScannerFlash();
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  Future<void> _switchCamera() async {
    await CardScannerService.instance.switchMobileScannerCamera();
  }

  void _startNfcScan() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    appState.setScanningStatus(true);

    await CardScannerService.instance.startNfcScanning();

    // Show scanning dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.nfc, color: const Color(0xFFff6600)),
              SizedBox(width: 8),
              Text('NFC Scanning'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Hold your NFC card near the device'),
              SizedBox(height: 8),
              Text(
                'Tap outside to cancel',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ).then((_) {
        CardScannerService.instance.stopNfcScanning();
        appState.setScanningStatus(false);
      });
    }
  }

  void _submitManualEntry() {
    final cardUid = _manualController.text.trim();
    if (cardUid.isNotEmpty &&
        CardScannerService.instance.isValidCardUid(cardUid)) {
      CardScannerService.instance.submitManualCardUid(cardUid);
      _manualController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid card UID'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final capabilities = CardScannerService.instance.getCapabilities();
        final stats = appState.getCurrentZoneStats();

        return Column(
          children: [
            // Zone Statistics Card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stats['zoneName'] ?? 'Unknown Zone',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: appState.isOnline
                                ? Colors.green
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            appState.isOnline ? 'ONLINE' : 'OFFLINE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Present',
                          value: '${stats['currentOccupancy'] ?? 0}',
                          color: Colors.green,
                        ),
                        _StatItem(
                          label: 'Capacity',
                          value: '${stats['capacity'] ?? 0}',
                          color: const Color(0xFFff6600),
                        ),
                        _StatItem(
                          label: 'Today',
                          value: '${stats['todayTotal'] ?? 0}',
                          color: Colors.purple,
                        ),
                        _StatItem(
                          label: 'Success',
                          value: '${stats['successRate'] ?? 0}%',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Scanning Interface
            Expanded(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Tab Bar
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFFff6600),
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(
                          icon: Icon(
                            Icons.qr_code_scanner,
                            color: capabilities['qr']! ? null : Colors.grey,
                          ),
                          text: 'QR Code',
                        ),
                        Tab(
                          icon: Icon(
                            Icons.nfc,
                            color: capabilities['nfc']! ? null : Colors.grey,
                          ),
                          text: 'NFC',
                        ),
                        Tab(
                          icon: Icon(
                            Icons.keyboard,
                            color: capabilities['manual']! ? null : Colors.grey,
                          ),
                          text: 'Manual',
                        ),
                      ],
                    ),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // QR Code Scanner
                          _buildQRScanner(capabilities['qr']!),

                          // NFC Scanner
                          _buildNFCScanner(capabilities['nfc']!),

                          // Manual Entry
                          _buildManualEntry(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildQRScanner(bool isAvailable) {
    if (!isAvailable) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('QR Code scanning not available on this device'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: mobileScannerController,
            onDetect: CardScannerService.instance.handleQrCode,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _toggleFlash,
                icon: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: _isFlashOn ? Colors.yellow : Colors.grey,
                ),
                tooltip: 'Toggle Flash',
              ),
              IconButton(
                onPressed: _switchCamera,
                icon: const Icon(Icons.flip_camera_android),
                tooltip: 'Switch Camera',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNFCScanner(bool isAvailable) {
    if (!isAvailable) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('NFC not available on this device'),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.nfc, size: 100, color: Color(0xFFff6600)),
          const SizedBox(height: 24),
          const Text(
            'Tap to start NFC scanning',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hold your NFC card near the device',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _startNfcScan,
            icon: const Icon(Icons.nfc),
            label: const Text('Start NFC Scan'),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntry() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.keyboard, size: 100, color: Color(0xFFff6600)),
          const SizedBox(height: 24),
          const Text(
            'Enter Card UID Manually',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _manualController,
            decoration: const InputDecoration(
              labelText: 'Card UID',
              hintText: 'e.g., CARD-001 or AA:BB:CC:DD',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.credit_card),
            ),
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _submitManualEntry(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitManualEntry,
              icon: const Icon(Icons.send),
              label: const Text('Submit'),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Supported formats:\n• Alphanumeric: CARD-001, USER123\n• Hex: AA:BB:CC:DD, AABBCCDD',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
