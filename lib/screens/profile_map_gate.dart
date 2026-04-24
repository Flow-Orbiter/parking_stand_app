import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mdm_sport/data/firebase/user_firestore.dart';
import 'package:mdm_sport/screens/map_screen.dart';
import 'package:mdm_sport/screens/profile_setup_screen.dart';

/// Po weryfikacji telefonu: profil w Firestore, potem mapa.
class ProfileMapGate extends StatefulWidget {
  const ProfileMapGate({super.key, required this.user});

  final User user;

  @override
  State<ProfileMapGate> createState() => _ProfileMapGateState();
}

class _ProfileMapGateState extends State<ProfileMapGate> {
  late Future<bool> _needSetupF;

  @override
  void initState() {
    super.initState();
    _needSetupF = _load();
  }

  @override
  void didUpdateWidget(ProfileMapGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _needSetupF = _load();
    }
  }

  Future<bool> _load() => UserFirestoreRepository().needsProfileSetup(widget.user.uid);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _needSetupF,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return ProfileSetupScreen(
            onCompleted: () {
              if (mounted) {
                setState(() {
                  _needSetupF = _load();
                });
              }
            },
          );
        }
        return const MapScreen();
      },
    );
  }
}
