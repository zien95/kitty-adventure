import 'package:shared_preferences/shared_preferences.dart';

class FreeUnlockService {
  bool _isInitialized = false;
  bool _isLoading = false;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isInitialized = true;
    await _markPremiumFree();
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required String email,
    required String amount,
    required String currency,
  }) async {
    await _markPremiumFree(email: email);
    return {
      'id': 'free_premium',
      'client_secret': 'free_premium',
      'amount': 0,
      'currency': currency,
      'receipt_email': email,
      'status': 'free',
    };
  }

  Future<bool> processPayment({
    required String email,
    required String amount,
    required String currency,
  }) async {
    _isLoading = true;
    try {
      await _markPremiumFree(email: email);
      return true;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _markPremiumFree({String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', true);
    await prefs.setString('premium_source', 'free');
    await prefs.setString('premium_purchase_token', 'free-premium');
    await prefs.setString('last_payment_amount', '0');
    await prefs.setString('last_payment_currency', getCurrency());
    await prefs.setString('last_payment_intent_id', 'free-premium');
    await prefs.setString(
      'last_payment_date',
      DateTime.now().toIso8601String(),
    );
    if (email != null && email.isNotEmpty) {
      await prefs.setString('last_payment_email', email);
    }
  }

  Future<bool> isPremiumPurchased() async {
    await _markPremiumFree();
    return true;
  }

  Future<String?> getPremiumPurchaseToken() async {
    await _markPremiumFree();
    return 'free-premium';
  }

  Future<Map<String, dynamic>?> getLastPaymentDetails() async {
    await _markPremiumFree();
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('last_payment_email'),
      'amount': '0',
      'currency': getCurrency(),
      'paymentIntentId': 'free-premium',
      'date': prefs.getString('last_payment_date'),
      'source': 'free',
    };
  }

  Future<bool> refundPayment(String paymentIntentId) async {
    await _markPremiumFree();
    return true;
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    return <Map<String, dynamic>>[
      {
        'paymentIntentId': 'free-premium',
        'amount': '0',
        'currency': 'aed',
        'source': 'free',
      },
    ];
  }

  Future<void> addToPaymentHistory(Map<String, dynamic> payment) async {
    await _markPremiumFree();
  }

  String getMonthlyPriceInCents() => '0';
  String getYearlyPriceInCents() => '0';

  double getMonthlyPriceDisplay() => 0;
  double getYearlyPriceDisplay() => 0;

  String getCurrency() => 'aed';

  void dispose() {}
}
