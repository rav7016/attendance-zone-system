import 'package:hive_flutter/hive_flutter.dart';
import '../models/person.dart';
import '../models/card.dart';
import '../models/zone.dart';
import '../models/reader.dart';
import '../models/attendance_event.dart';
import '../models/auth_snapshot.dart';
import '../models/constituency.dart';
import '../models/user.dart';

class DatabaseService {
  static const String _personBoxName = 'persons';
  static const String _cardBoxName = 'cards';
  static const String _zoneBoxName = 'zones';
  static const String _readerBoxName = 'readers';
  static const String _eventBoxName = 'events';
  static const String _snapshotBoxName = 'snapshots';
  static const String _snapshotItemBoxName = 'snapshot_items';
  static const String _constituencyBoxName = 'constituencies';
  static const String _userBoxName = 'users';

  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  DatabaseService._();

  late Box<Person> _personBox;
  late Box<Card> _cardBox;
  late Box<Zone> _zoneBox;
  late Box<Reader> _readerBox;
  late Box<AttendanceEvent> _eventBox;
  late Box<AuthSnapshot> _snapshotBox;
  late Box<AuthSnapshotItem> _snapshotItemBox;
  late Box<Constituency> _constituencyBox;
  late Box<User> _userBox;

  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(PersonAdapter());
    Hive.registerAdapter(CardAdapter());
    Hive.registerAdapter(CardTypeAdapter());
    Hive.registerAdapter(CardStateAdapter());
    Hive.registerAdapter(ZoneAdapter());
    Hive.registerAdapter(ReaderAdapter());
    Hive.registerAdapter(AttendanceEventAdapter());
    Hive.registerAdapter(DecisionAdapter());
    Hive.registerAdapter(ReasonCodeAdapter());
    Hive.registerAdapter(AuthSnapshotAdapter());
    Hive.registerAdapter(AuthSnapshotItemAdapter());
    Hive.registerAdapter(ConstituencyAdapter());
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(UserRoleAdapter());

    // Open boxes
    _personBox = await Hive.openBox<Person>(_personBoxName);
    _cardBox = await Hive.openBox<Card>(_cardBoxName);
    _zoneBox = await Hive.openBox<Zone>(_zoneBoxName);
    _readerBox = await Hive.openBox<Reader>(_readerBoxName);
    _eventBox = await Hive.openBox<AttendanceEvent>(_eventBoxName);
    _snapshotBox = await Hive.openBox<AuthSnapshot>(_snapshotBoxName);
    _snapshotItemBox = await Hive.openBox<AuthSnapshotItem>(
      _snapshotItemBoxName,
    );
    _constituencyBox = await Hive.openBox<Constituency>(_constituencyBoxName);
    _userBox = await Hive.openBox<User>(_userBoxName);
  }

  // Person operations
  Future<void> savePerson(Person person) async {
    await _personBox.put(person.personId, person);
  }

  Person? getPerson(int personId) {
    return _personBox.get(personId);
  }

  List<Person> getAllPersons() {
    return _personBox.values.toList();
  }

  // Card operations
  Future<void> saveCard(Card card) async {
    await _cardBox.put(card.cardUid, card);
  }

  Card? getCard(String cardUid) {
    return _cardBox.get(cardUid);
  }

  List<Card> getAllCards() {
    return _cardBox.values.toList();
  }

  List<Card> getCardsByPerson(int personId) {
    return _cardBox.values.where((card) => card.personId == personId).toList();
  }

  // Zone operations
  Future<void> saveZone(Zone zone) async {
    await _zoneBox.put(zone.zoneId, zone);
  }

  Zone? getZone(int zoneId) {
    return _zoneBox.get(zoneId);
  }

  List<Zone> getAllZones() {
    return _zoneBox.values.toList();
  }

  // Reader operations
  Future<void> saveReader(Reader reader) async {
    await _readerBox.put(reader.readerId, reader);
  }

  Reader? getReader(String readerId) {
    return _readerBox.get(readerId);
  }

  List<Reader> getReadersByZone(int zoneId) {
    return _readerBox.values
        .where((reader) => reader.zoneId == zoneId)
        .toList();
  }

  // Attendance Event operations
  Future<void> saveEvent(AttendanceEvent event) async {
    await _eventBox.put(event.eventId, event);
  }

  List<AttendanceEvent> getAllEvents() {
    return _eventBox.values.toList();
  }

  List<AttendanceEvent> getEventsByZone(int zoneId) {
    return _eventBox.values.where((event) => event.zoneId == zoneId).toList();
  }

  List<AttendanceEvent> getEventsByCard(String cardUid) {
    return _eventBox.values.where((event) => event.cardUid == cardUid).toList();
  }

  List<AttendanceEvent> getUnsyncedEvents() {
    return _eventBox.values.where((event) => event.needsSync).toList();
  }

  // Auth Snapshot operations
  Future<void> saveSnapshot(AuthSnapshot snapshot) async {
    await _snapshotBox.put(snapshot.snapshotId, snapshot);

    // Clear old snapshot items
    await _snapshotItemBox.clear();

    // Save new snapshot items
    for (var item in snapshot.items) {
      await _snapshotItemBox.put(item.cardUid, item);
    }
  }

  AuthSnapshot? getLatestSnapshot() {
    if (_snapshotBox.isEmpty) return null;

    var snapshots = _snapshotBox.values.toList();
    snapshots.sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
    return snapshots.first;
  }

  AuthSnapshotItem? getSnapshotItem(String cardUid) {
    return _snapshotItemBox.get(cardUid);
  }

  Future<void> saveSnapshotItem(String cardUid, AuthSnapshotItem item) async {
    await _snapshotItemBox.put(cardUid, item);
  }

  // Constituency operations
  Future<void> saveConstituency(Constituency constituency) async {
    await _constituencyBox.put(constituency.constituencyNo, constituency);
  }

  Constituency? getConstituency(int constituencyNo) {
    return _constituencyBox.get(constituencyNo);
  }

  List<Constituency> getAllConstituencies() {
    return _constituencyBox.values.toList()
      ..sort((a, b) => a.constituencyNo.compareTo(b.constituencyNo));
  }

  List<Constituency> getConstituenciesByEthnicMajority(String ethnicMajority) {
    return _constituencyBox.values
        .where(
          (constituency) => constituency.ethnicMajority.toLowerCase().contains(
            ethnicMajority.toLowerCase(),
          ),
        )
        .toList()
      ..sort((a, b) => a.constituencyNo.compareTo(b.constituencyNo));
  }

  int getTotalElectoralPopulation() {
    return _constituencyBox.values.fold(
      0,
      (sum, constituency) => sum + constituency.electoralPopulation,
    );
  }

  // User operations
  Future<void> saveUser(User user) async {
    await _userBox.put(user.userId, user);
  }

  User? getUser(String userId) {
    return _userBox.get(userId);
  }

  User? getUserByUsernameOrEmail(String usernameOrEmail) {
    return _userBox.values.cast<User?>().firstWhere(
      (user) =>
          user != null &&
          (user.username.toLowerCase() == usernameOrEmail.toLowerCase() ||
              user.email.toLowerCase() == usernameOrEmail.toLowerCase()),
      orElse: () => null,
    );
  }

  List<User> getAllUsers() {
    return _userBox.values.toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  List<User> getActiveUsers() {
    return _userBox.values.where((user) => user.isActive).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  List<User> getUsersByRole(UserRole role) {
    return _userBox.values.where((user) => user.role == role).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  List<User> getUsersByConstituency(int constituencyNo) {
    return _userBox.values
        .where((user) => user.assignedConstituencies.contains(constituencyNo))
        .toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  Future<void> deleteUser(String userId) async {
    await _userBox.delete(userId);
  }

  // Utility methods
  Future<void> clearAllData() async {
    await _personBox.clear();
    await _cardBox.clear();
    await _zoneBox.clear();
    await _readerBox.clear();
    await _eventBox.clear();
    await _snapshotBox.clear();
    await _snapshotItemBox.clear();
    await _constituencyBox.clear();
    await _userBox.clear();
  }

  // Statistics
  int get totalPersons => _personBox.length;
  int get totalCards => _cardBox.length;
  int get totalZones => _zoneBox.length;
  int get totalReaders => _readerBox.length;
  int get totalEvents => _eventBox.length;
  int get totalConstituencies => _constituencyBox.length;
  int get totalUsers => _userBox.length;
  int get unsyncedEventCount => getUnsyncedEvents().length;
}
