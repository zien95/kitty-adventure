import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';

class AccountProvider extends ChangeNotifier {
  Account? _account;
  bool _isLoggedIn = false;
  bool _isLoading = false;

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
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final accountJson = prefs.getString('user_account');

    if (accountJson != null) {
      _account = Account.fromJson(json.decode(accountJson));
      _account!.isPremium = true;
      _isLoggedIn = true;

      await _syncPremiumStatus();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _syncPremiumStatus() async {
    if (_account != null) {
      _account!.isPremium = true;
      await _saveAccount();
    }
  }

  Future<void> login(String username, String email) async {
    _isLoading = true;
    notifyListeners();

    final newAccount = Account(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      email: email,
      createdAt: DateTime.now(),
      isPremium: true,
    );

    _account = newAccount;
    _isLoggedIn = true;

    await _saveAccount();

    await _syncPremiumStatus();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveAccount() async {
    if (_account == null) return;

    _account!.isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_account', json.encode(_account!.toJson()));
  }

  Future<void> logout() async {
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
}
