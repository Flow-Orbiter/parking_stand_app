import 'package:firebase_auth/firebase_auth.dart';

/// Czy użytkownik ma w Firebase zweryfikowany numer (E.162 w [User.phoneNumber]).
/// Bez tego użytkownik nie powinien wchodzić do głównej treści aplikacji.
bool hasVerifiedAppPhone(User? user) {
  if (user == null) return false;
  final p = user.phoneNumber;
  return p != null && p.isNotEmpty;
}
