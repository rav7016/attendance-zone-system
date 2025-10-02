import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart' as app_user;
import '../models/constituency.dart';
import '../models/person.dart';
import '../models/card.dart';
import '../models/zone.dart';
import '../models/reader.dart';
import '../models/attendance_event.dart';
import '../models/auth_snapshot.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  FirebaseService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _constituencies =>
      _firestore.collection('constituencies');
  CollectionReference get _persons => _firestore.collection('persons');
  CollectionReference get _cards => _firestore.collection('cards');
  CollectionReference get _zones => _firestore.collection('zones');
  CollectionReference get _readers => _firestore.collection('readers');
  CollectionReference get _events => _firestore.collection('attendance_events');
  CollectionReference get _snapshots => _firestore.collection('auth_snapshots');

  // User operations
  Future<void> saveUser(app_user.User user) async {
    await _users.doc(user.userId).set(user.toJson());
  }

  Future<app_user.User?> getUser(String userId) async {
    final doc = await _users.doc(userId).get();
    if (doc.exists) {
      return app_user.User.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<app_user.User?> getUserByUsernameOrEmail(
    String usernameOrEmail,
  ) async {
    // Try username first
    var query = await _users
        .where('username', isEqualTo: usernameOrEmail.toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return app_user.User.fromJson(
        query.docs.first.data() as Map<String, dynamic>,
      );
    }

    // Try email
    query = await _users
        .where('email', isEqualTo: usernameOrEmail.toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return app_user.User.fromJson(
        query.docs.first.data() as Map<String, dynamic>,
      );
    }

    return null;
  }

  Future<List<app_user.User>> getAllUsers() async {
    final query = await _users.orderBy('fullName').get();
    return query.docs
        .map(
          (doc) => app_user.User.fromJson(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // Constituency operations
  Future<void> saveConstituency(Constituency constituency) async {
    await _constituencies
        .doc(constituency.constituencyNo.toString())
        .set(constituency.toJson());
  }

  Future<Constituency?> getConstituency(int constituencyNo) async {
    final doc = await _constituencies.doc(constituencyNo.toString()).get();
    if (doc.exists) {
      return Constituency.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Constituency>> getAllConstituencies() async {
    final query = await _constituencies.orderBy('constituencyNo').get();
    return query.docs
        .map((doc) => Constituency.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Person operations
  Future<void> savePerson(Person person) async {
    await _persons.doc(person.personId.toString()).set(person.toJson());
  }

  Future<Person?> getPerson(int personId) async {
    final doc = await _persons.doc(personId.toString()).get();
    if (doc.exists) {
      return Person.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Person>> getAllPersons() async {
    final query = await _persons.get();
    return query.docs
        .map((doc) => Person.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Card operations
  Future<void> saveCard(Card card) async {
    await _cards.doc(card.cardUid).set(card.toJson());
  }

  Future<Card?> getCard(String cardUid) async {
    final doc = await _cards.doc(cardUid).get();
    if (doc.exists) {
      return Card.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Card>> getAllCards() async {
    final query = await _cards.get();
    return query.docs
        .map((doc) => Card.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Zone operations
  Future<void> saveZone(Zone zone) async {
    await _zones.doc(zone.zoneId.toString()).set(zone.toJson());
  }

  Future<Zone?> getZone(int zoneId) async {
    final doc = await _zones.doc(zoneId.toString()).get();
    if (doc.exists) {
      return Zone.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Zone>> getAllZones() async {
    final query = await _zones.get();
    return query.docs
        .map((doc) => Zone.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Reader operations
  Future<void> saveReader(Reader reader) async {
    await _readers.doc(reader.readerId).set(reader.toJson());
  }

  Future<Reader?> getReader(String readerId) async {
    final doc = await _readers.doc(readerId).get();
    if (doc.exists) {
      return Reader.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Attendance Event operations
  Future<void> saveEvent(AttendanceEvent event) async {
    await _events.doc(event.eventId).set(event.toJson());
  }

  Future<List<AttendanceEvent>> getUnsyncedEvents() async {
    final query = await _events.where('synced', isEqualTo: false).get();
    return query.docs
        .map(
          (doc) => AttendanceEvent.fromJson(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<AttendanceEvent>> getEventsByZone(int zoneId) async {
    final query = await _events.where('zoneId', isEqualTo: zoneId).get();
    return query.docs
        .map(
          (doc) => AttendanceEvent.fromJson(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // Snapshot operations
  Future<void> saveSnapshotItem(String cardUid, AuthSnapshotItem item) async {
    await _snapshots.doc(cardUid).set(item.toJson());
  }

  Future<AuthSnapshotItem?> getSnapshotItem(String cardUid) async {
    final doc = await _snapshots.doc(cardUid).get();
    if (doc.exists) {
      return AuthSnapshotItem.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Statistics
  Future<int> getTotalUsers() async {
    final query = await _users.count().get();
    return query.count ?? 0;
  }

  Future<int> getTotalConstituencies() async {
    final query = await _constituencies.count().get();
    return query.count ?? 0;
  }

  Future<int> getTotalPersons() async {
    final query = await _persons.count().get();
    return query.count ?? 0;
  }

  Future<int> getTotalCards() async {
    final query = await _cards.count().get();
    return query.count ?? 0;
  }

  Future<int> getTotalEvents() async {
    final query = await _events.count().get();
    return query.count ?? 0;
  }

  // Utility methods
  Future<void> clearAllData() async {
    // Note: In production, you'd want to be more careful about this
    final batch = _firestore.batch();

    // This is a simplified version - in production you'd need to handle pagination
    final collections = [
      _users,
      _constituencies,
      _persons,
      _cards,
      _zones,
      _readers,
      _events,
      _snapshots,
    ];

    for (final collection in collections) {
      final docs = await collection.get();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }
}
