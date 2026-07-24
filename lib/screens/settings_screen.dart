import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../services/update_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _checkingForUpdates = false;
  String? _updateStatus;

  Future<void> _checkForUpdatesNow() async {
    setState(() {
      _checkingForUpdates = true;
      _updateStatus = 'Checking for updates...';
    });

    final result = await UpdateService.checkForUpdates(
      context,
      showNoUpdateSnack: true,
    );

    if (!mounted) return;
    setState(() {
      _checkingForUpdates = false;
      _updateStatus = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final darkMode = gameProvider.darkModeEnabled;
        final backgroundColor =
            darkMode ? const Color(0xFF151827) : const Color(0xFFFFF7D6);
        final cardColor = darkMode ? const Color(0xFF24283B) : Colors.white;
        final textColor =
            darkMode ? const Color(0xFFFFEAC2) : const Color(0xFF7A4B3B);
        final subTextColor =
            darkMode ? const Color(0xFFFFC98E) : const Color(0xFF9F6834);

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: const Text('⚙️ Settings'),
            backgroundColor:
                darkMode ? const Color(0xFF24283B) : const Color(0xFFFF76B7),
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _settingsCard(
                    cardColor: cardColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              darkMode
                                  ? Icons.dark_mode
                                  : Icons.light_mode_outlined,
                              color: const Color(0xFFFF76B7),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              darkMode ? 'Dark Mode' : 'Light Mode',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: darkMode,
                          onChanged: (_) => gameProvider.toggleDarkMode(),
                          activeThumbColor: const Color(0xFFFF76B7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _settingsCard(
                    cardColor: cardColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.volume_up, color: subTextColor),
                            const SizedBox(width: 12),
                            Text(
                              'Sound',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: gameProvider.soundEnabled,
                          onChanged: (_) => gameProvider.toggleSound(),
                          activeThumbColor: const Color(0xFF7B1FA2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _settingsCard(
                    cardColor: cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Updates',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You have Zona Pets v${UpdateService.currentVersion}.',
                          style: TextStyle(color: subTextColor, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'We will let you know when a new adventure is ready.',
                          style: TextStyle(color: subTextColor, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _checkingForUpdates
                                ? null
                                : _checkForUpdatesNow,
                            icon: _checkingForUpdates
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                            label: Text(
                              _checkingForUpdates
                                  ? 'Checking...'
                                  : 'Check for Updates',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF76B7),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        if (_updateStatus != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _updateStatus!,
                            style: TextStyle(color: subTextColor, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _settingsCard(
                    cardColor: cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎮 Zona Pets v${UpdateService.currentVersion}',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '🛠️ WHAT\'S NEW:\n• Bug fixes\n• Cat profiles and jobs\n• Room action bonuses\n• Outfit set bonuses\n• Secret codes\n• Easter Egg Journal\n• Group play cutscene',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _settingsCard(
                    cardColor: cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ Reset Game',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This will delete all your progress. Are you sure?',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showResetDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Reset Game',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _settingsCard({
    required Color cardColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  void _showResetDialog(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            darkMode ? const Color(0xFF1A1D2B) : const Color(0xFFFFF7D6),
        title: Text(
          'Reset Game?',
          style: TextStyle(
            color: darkMode ? const Color(0xFFFFEAC2) : Color(0xFF7A4B3B),
          ),
        ),
        content: Text(
          'This will delete all your progress. Are you sure?',
          style: TextStyle(
            color: darkMode ? const Color(0xFFFFC98E) : Color(0xFF9F6834),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<GameProvider>().resetGame();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
