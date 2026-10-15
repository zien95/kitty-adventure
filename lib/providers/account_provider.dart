import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';

class AccountProvider extends ChangeNotifier {
  Account? _account;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  StreamSubscription<User?>? _authSubscription;
  int _authRevision = 0;
  bool _disposed = false;

  Account? get account {
    if (_account != null && !_account!.isPremium) {
      _account!.isPremium = true;
    }
    return _account;
  }

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isPremium => true;

  AccountProvider() {
    if (Firebase.apps.isNotEmpty) {
      _isLoading = true;
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
            (user) => unawaited(_applyAuthUser(user)),
          );
    }
  }

  Future<void> _applyAuthUser(User? user) async {
    final revision = ++_authRevision;
    _account = null;
    _isLoggedIn = false;
    _isLoading = true;
    notifyListeners();
    try {
      if (user == null) return;
      final prefs = await SharedPreferences.getInstance();
      Account? previous;
      try {
        final saved = prefs.getString('user_account');
        if (saved != null) previous = Account.fromJson(jsonDecode(saved));
      } catch (_) {/* A legacy local profile is never authentication. */}
      if (_disposed || revision != _authRevision) return;
      final sameOwner = previous != null && previous.email == user.email;
      _account = Account.fromJson({
        if (sameOwner) ...previous!.toJson(),
        'id': user.uid,
        'username': user.displayName ??
            (sameOwner
                ? previous!.username
                : user.email?.split('@').first ?? 'Pet Friend'),
        'email': user.email ?? '',
        'createdAt':
            (user.metadata.creationTime ?? DateTime.now()).toIso8601String(),
        'isPremium': true,
      });
      _isLoggedIn = true;
      await _saveAccount();
    } finally {
      if (!_disposed && revision == _authRevision) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _syncPremiumStatus() async {
    if (_account != null) {
      _account!.isPremium = true;
      await _saveAccount();
    }
  }

  Future<void> login(String email, String password) async {
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> _saveAccount() async {
    if (_account == null) return;

    _account!.isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_account', json.encode(_account!.toJson()));
  }

  Future<void> logout() async {
    if (Firebase.apps.isNotEmpty) await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_account');

    _account = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> updateStats({
    int? totalPlayTime,
    int? achievementsUnlocked,
    int? coins,
    int? gems,
    bool? isPremium,
  }) async {
    if (_account == null) return;

    if (totalPlayTime != null) _account!.totalPlayTime += totalPlayTime;
    if (achievementsUnlocked != null) {
      _account!.achievementsUnlocked += achievementsUnlocked;
    }
    if (coins != null) _account!.coins += coins;
    if (gems != null) _account!.gems += gems;
    _account!.isPremium = true;

    await _saveAccount();
    notifyListeners();
  }

  Future<void> unlockFeature(String feature) async {
    if (_account == null) return;

    if (!_account!.unlockedFeatures.contains(feature)) {
      _account!.unlockedFeatures.add(feature);
      await _saveAccount();
      notifyListeners();
    }
  }

  Future<bool> checkPremiumStatus() async {
    await _syncPremiumStatus();
    return true;
  }

  Future<String?> getPurchaseToken() async {
    return 'free-premium';
  }

  Future<Map<String, dynamic>?> getLastPaymentDetails() async {
    return {'source': 'free', 'status': 'unlocked', 'amount': 0};
  }

  @override
  void dispose() {
    _disposed = true;
    _authRevision++;
    _authSubscription?.cancel();
    super.dispose();
  }
}
