import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// import 'package:nfc_manager/nfc_manager.dart';  // Temporarily disabled for Android compatibility
import 'package:mobile_scanner/mobile_scanner.dart';

enum ScanMode { nfc, qr, manual }

class ScanResult {
  final String cardUid;
  final ScanMode scanMode;
  final DateTime timestamp;
  final String? rawData;

  ScanResult({
    required this.cardUid,
    required this.scanMode,
    DateTime? timestamp,
    this.rawData,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'ScanResult{cardUid: $cardUid, scanMode: $scanMode, timestamp: $timestamp}';
  }
}

class CardScannerService {
  static CardScannerService? _instance;
  static CardScannerService get instance =>
      _instance ??= CardScannerService._();
  CardScannerService._();

  StreamController<ScanResult>? _scanController;
  MobileScannerController? _mobileScannerController;
  bool _isNfcAvailable = false;
  bool _isScanning = false;

  Stream<ScanResult> get scanStream =>
      _scanController?.stream ?? const Stream.empty();
  bool get isNfcAvailable => _isNfcAvailable;
  bool get isScanning => _isScanning;

  /// Initialize the scanner service
  Future<void> initialize() async {
    _scanController = StreamController<ScanResult>.broadcast();

    // Check NFC availability (temporarily disabled for Android compatibility)
    try {
      // _isNfcAvailable = await NfcManager.instance.isAvailable();
      _isNfcAvailable = false; // Temporarily disabled
    } catch (e) {
      _isNfcAvailable = false;
      // NFC not available
    }
  }

  /// Start NFC scanning (temporarily disabled for Android compatibility)
  Future<void> startNfcScanning() async {
    if (!_isNfcAvailable || _isScanning) return;

    _isScanning = true;

    try {
      // await NfcManager.instance.startSession(
      //   onDiscovered: (NfcTag tag) async {
      //     await _handleNfcTag(tag);
      //   },
      // );
      // NFC temporarily disabled
      _isScanning = false;
    } catch (e) {
      // Error starting NFC session
      _isScanning = false;
    }
  }

  /// Stop NFC scanning (temporarily disabled for Android compatibility)
  Future<void> stopNfcScanning() async {
    if (!_isScanning) return;

    try {
      // await NfcManager.instance.stopSession();
      _isScanning = false;
    } catch (e) {
      // Error stopping NFC session
    }
  }

  /// Handle NFC tag discovery (temporarily disabled for Android compatibility)
  Future<void> _handleNfcTag(dynamic tag) async {
    // NFC functionality temporarily disabled for Android compatibility
    // This method will be re-enabled once NFC manager compatibility issues are resolved
    return;
  }

  /// Set mobile scanner controller for QR scanning
  void setMobileScannerController(MobileScannerController controller) {
    _mobileScannerController = controller;
  }

  /// Handle QR code scan
  void handleQrCode(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        final scanResult = ScanResult(
          cardUid: barcode.rawValue!,
          scanMode: ScanMode.qr,
          rawData: barcode.rawValue,
        );

        _scanController?.add(scanResult);

        // Provide haptic feedback
        HapticFeedback.lightImpact();
      }
    }
  }

  /// Manual card UID entry
  void submitManualCardUid(String cardUid) {
    if (cardUid.trim().isNotEmpty) {
      final scanResult = ScanResult(
        cardUid: cardUid.trim().toUpperCase(),
        scanMode: ScanMode.manual,
      );

      _scanController?.add(scanResult);
    }
  }

  /// Toggle mobile scanner flash
  Future<void> toggleMobileScannerFlash() async {
    await _mobileScannerController?.toggleTorch();
  }

  /// Switch mobile scanner camera
  Future<void> switchMobileScannerCamera() async {
    await _mobileScannerController?.switchCamera();
  }

  /// Validate card UID format
  bool isValidCardUid(String cardUid) {
    if (cardUid.isEmpty) return false;

    // Accept various formats:
    // - Hex with colons: AA:BB:CC:DD
    // - Hex without colons: AABBCCDD
    // - Alphanumeric: CARD001, USER123, etc.

    final hexPattern = RegExp(r'^[A-F0-9:]{4,}$');
    final alphanumericPattern = RegExp(r'^[A-Z0-9]{3,}$');

    final upperCardUid = cardUid.toUpperCase();
    return hexPattern.hasMatch(upperCardUid) ||
        alphanumericPattern.hasMatch(upperCardUid);
  }

  /// Format card UID consistently
  String formatCardUid(String cardUid) {
    return cardUid.trim().toUpperCase();
  }

  /// Get scanner capabilities
  Map<String, bool> getCapabilities() {
    return {
      'nfc': _isNfcAvailable,
      'qr': !kIsWeb, // QR scanning available on mobile platforms, not web
      'manual': true,
    };
  }

  /// Dispose resources
  void dispose() {
    stopNfcScanning();
    _mobileScannerController?.dispose();
    _scanController?.close();
    _scanController = null;
  }
}
