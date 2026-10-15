import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zona_pets/providers/account_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('a legacy local profile does not count as a Firebase login', () async {
    SharedPreferences.setMockInitialValues({
      'user_account': jsonEncode({
        'id': 'legacy',
        'username': 'Friend',
        'email': 'friend@example.invalid'
      })
    });
    final account = AccountProvider();
    expect(account.isLoggedIn, isFalse);
    expect(account.account, isNull);
    expect(account.isPremium, isTrue);
    expect((await SharedPreferences.getInstance()).containsKey('user_account'),
        isTrue);
    account.dispose();
  });
}
