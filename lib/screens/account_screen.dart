import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1FA2),
        title: const Text('Account', style: TextStyle(color: Colors.white)),
      ),
      body: Consumer<AccountProvider>(
        builder: (context, accountProvider, child) {
          if (accountProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!accountProvider.isLoggedIn) {
            return _buildLoginScreen(context, accountProvider);
          }

          return _buildAccountScreen(context, accountProvider);
        },
      ),
    );
  }

  Widget _buildLoginScreen(
      BuildContext context, AccountProvider accountProvider) {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 100, color: Color(0xFF7B1FA2)),
          const SizedBox(height: 20),
          const Text('Welcome to Pet Care!',
              style: TextStyle(fontSize: 24, color: Colors.white)),
          const SizedBox(height: 30),
          TextField(
            controller: usernameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: const TextStyle(color: Colors.white70),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: const TextStyle(color: Colors.white70),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              if (usernameController.text.isNotEmpty &&
                  emailController.text.isNotEmpty) {
                accountProvider.login(
                    usernameController.text, emailController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B1FA2),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
            child: const Text('Create Account',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountScreen(
      BuildContext context, AccountProvider accountProvider) {
    final account = accountProvider.account!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3D3D4A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.account_circle,
                    size: 80, color: Color(0xFF7B1FA2)),
                const SizedBox(height: 10),
                Text(account.username,
                    style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                Text(account.email,
                    style: const TextStyle(color: Colors.white70)),
                Text(
                    'Member since ${account.createdAt.day}/${account.createdAt.month}/${account.createdAt.year}',
                    style: const TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('💰 Coins', '${account.coins}', Colors.yellow),
              _buildStatCard('💎 Gems', '${account.gems}', Colors.cyan),
              _buildStatCard('🏆 Achievements',
                  '${account.achievementsUnlocked}', Colors.orange),
              _buildStatCard('🐾 Pets', '${account.petsOwned}', Colors.pink),
            ],
          ),
          const SizedBox(height: 20),

          // Premium Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: account.isPremium
                  ? Colors.amber.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: account.isPremium ? Colors.amber : Colors.grey),
            ),
            child: Row(
              children: [
                Icon(account.isPremium ? Icons.star : Icons.star_border,
                    color: account.isPremium ? Colors.amber : Colors.grey),
                const SizedBox(width: 10),
                Text(account.isPremium ? 'Premium Member' : 'Free Account',
                    style: TextStyle(
                        color: account.isPremium ? Colors.amber : Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Logout Button
          ElevatedButton.icon(
            onPressed: accountProvider.logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D4A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
