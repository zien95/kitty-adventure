class PaymentService {
  bool _isAvailable = true;

  bool get isAvailable => _isAvailable;
  List<Map<String, dynamic>> get products => const [
        {
          'id': 'free_premium',
          'title': 'Premium',
          'price': 'Free',
        },
      ];
  List<Map<String, dynamic>> get purchases => const [
        {
          'id': 'free_premium',
          'status': 'unlocked',
        },
      ];

  Future<void> initialize() async {
    _isAvailable = true;
  }

  Future<bool> purchasePremiumMonthly() async => true;

  Future<bool> purchasePremiumYearly() async => true;

  Future<bool> isPremiumPurchased() async => true;

  Map<String, dynamic>? getPremiumMonthlyProduct() => products.first;

  Map<String, dynamic>? getPremiumYearlyProduct() => products.first;

  void dispose() {}
}
