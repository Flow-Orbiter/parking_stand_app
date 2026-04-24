import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Dostęp do Firestore powiązany z kontem z [FirebaseAuth].
///
/// Domyślnie: kolekcja `users`, dokument `uid`. Zmień [usersCollection], jeśli Twoja
/// gotowa struktura w konsoli używa innej ścieżki.
class UserFirestoreRepository {
  UserFirestoreRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Ustaw na nazwę kolekcji z Twojej bazy (np. `clients`, `profiles`).
  static const String usersCollection = 'users';

  /// `set(..., merge: true)` — nie kasuje pól, które masz już w dokumencie w konsoli.
  Future<void> ensureUserDocument(User user) async {
    final doc = _db.collection(usersCollection).doc(user.uid);
    await doc.set(
      {
        'uid': user.uid,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'authProviders': user.providerData.map((p) => p.providerId).toList(),
      },
      SetOptions(merge: true),
    );
  }

  /// Czy użytkownik musi przejść ekran uzupełnienia profilu (pierwsze wejście / brak flagi w Firestore).
  Future<bool> needsProfileSetup(String uid) async {
    final doc = await _db.collection(usersCollection).doc(uid).get();
    if (!doc.exists) return true;
    if (doc.data()!['profileCompleted'] == true) return false;
    return true;
  }

  /// Zapis danych profilu (imię, opcjonalny e-mail kontaktowy). Ustawia [profileCompleted] w Firestore
  /// i [User.displayName] w Firebase Auth.
  Future<void> completeProfile(
    User user, {
    required String displayName,
    String? contactEmail,
  }) async {
    final name = displayName.trim();
    if (name.isEmpty) {
      throw ArgumentError('displayName');
    }
    await user.updateDisplayName(name);
    await user.reload();
    final mail = contactEmail?.trim();
    final docRef = _db.collection(usersCollection).doc(user.uid);
    await docRef.set(
      {
        'uid': user.uid,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'displayName': name,
        'photoURL': user.photoURL,
        'profileCompleted': true,
        'contactEmail': (mail != null && mail.isNotEmpty) ? mail : null,
        'updatedAt': FieldValue.serverTimestamp(),
        'authProviders': user.providerData.map((p) => p.providerId).toList(),
      },
      SetOptions(merge: true),
    );
  }

  /// Podgląd pól w menu (nazwa, e-mail z profilu / konta).
  Stream<Map<String, dynamic>?> userProfileDataStream(String uid) {
    return _db
        .collection(usersCollection)
        .doc(uid)
        .snapshots()
        .map((s) => s.data());
  }
}
