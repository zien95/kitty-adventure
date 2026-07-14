import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../providers/game_provider.dart';
import '../models/pet.dart';
import '../screens/cloud_backup_screen.dart';
import '../screens/pet_sharing_screen.dart';
import '../screens/user_account_screen.dart';

class DataTransferScreen extends StatefulWidget {
  const DataTransferScreen({super.key});

  @override
  State<DataTransferScreen> createState() => _DataTransferScreenState();
}

class _DataTransferScreenState extends State<DataTransferScreen> {
  bool _isTransferring = false;
  String _statusMessage = 'Ready to transfer data';
  String? _lastTransferTime;
  bool _isWifiServer = false;
  String _wifiStatus = 'Not connected';
  String? _serverIP;
  HttpServer? _httpServer;

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  @override
  void dispose() {
    _httpServer?.close();
    super.dispose();
  }

  Future<void> _loadGameData() async {
    try {
      // First check SharedPreferences directly
      final prefs = await SharedPreferences.getInstance();
      final petJson = prefs.getString('pet');

      setState(() {
        if (petJson != null) {
          _statusMessage =
              'Pet data found in storage (${petJson.length} chars), loading...';
        } else {
          _statusMessage = 'No pet data in storage - please create a pet first';
        }
      });

      final gameProvider = context.read<GameProvider>();

      await gameProvider.loadGame();
      if (!mounted) return;

      // Check pet status after loading
      final pet = gameProvider.pet;
      final hasPet = gameProvider.hasPet;

      setState(() {
        if (pet != null) {
          _statusMessage = '✅ Pet loaded: ${pet.name} (Level ${pet.level})';
        } else if (hasPet) {
          _statusMessage = '⚠️ Pet exists but data is incomplete';
        } else if (petJson != null) {
          _statusMessage =
              '❌ Pet data exists but failed to load - trying direct parse...';
          _tryDirectPetLoad(petJson);
        } else {
          _statusMessage = '❌ No pet found - please create a pet first';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error loading game data: $e';
      });
    }
  }

  Future<void> _tryDirectPetLoad(String petJson) async {
    try {
      final petData = jsonDecode(petJson);
      final pet = Pet.fromJson(petData);

      // Set the pet directly in GameProvider
      final gameProvider = context.read<GameProvider>();
      gameProvider.setPet(pet);

      setState(() {
        _statusMessage =
            '✅ Pet loaded directly: ${pet.name} (Level ${pet.level})';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Direct pet load failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1FA2),
        title: const Text(
          '📁 USB Data Transfer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UserAccountScreen()),
                );
              },
              icon: const Icon(Icons.account_circle,
                  color: Colors.white, size: 24),
              tooltip: 'User Account',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Access Account Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.2),
                    Colors.purple.withValues(alpha: 0.2)
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UserAccountScreen()),
                  );
                },
                icon: const Icon(Icons.account_circle, size: 20),
                label: const Text('👤 User Account Login',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Status Card
            _buildStatusCard(),

            const SizedBox(height: 24),

            // Export Section
            _buildSectionTitle('📤 EXPORT DATA'),
            _buildExportSection(),

            const SizedBox(height: 24),

            // Import Section
            _buildSectionTitle('📥 IMPORT DATA'),
            _buildImportSection(),

            const SizedBox(height: 24),

            // WiFi Transfer Section
            _buildSectionTitle('📶 WIFI TRANSFER'),
            _buildWifiSection(),

            const SizedBox(height: 24),

            _buildSectionTitle('☁️ CLOUD BACKUP'),
            _buildCloudSection(),

            const SizedBox(height: 24),

            _buildSectionTitle('🐾 PET SHARING'),
            _buildSharingSection(),

            const SizedBox(height: 24),

            _buildSectionTitle('👤 ACCOUNT'),
            _buildAccountSection(),

            const SizedBox(height: 24),

            // Instructions
            _buildSectionTitle('📋 INSTRUCTIONS'),
            _buildInstructions(),

            const SizedBox(height: 24),

            // Back Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Game',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.2),
            Colors.purple.withValues(alpha: 0.2)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isTransferring ? Icons.sync : Icons.usb,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Transfer Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _statusMessage));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Status copied to clipboard!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.white, size: 16),
                tooltip: 'Copy Status',
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _statusMessage));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Status copied to clipboard!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (_lastTransferTime != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Last transfer: $_lastTransferTime',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _lastTransferTime!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Time copied to clipboard!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, color: Colors.grey, size: 12),
                  tooltip: 'Copy Time',
                ),
              ],
            ),
          ],
          if (_isTransferring) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final pet = gameProvider.pet;

        // Always show the export section with a test pet option
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF3D3D4A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.pets, color: pet?.type.color ?? Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet?.name ?? 'Test Pet (Create for Export)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Level ${pet?.level ?? 1} • ${pet?.type.emoji ?? '🐾'}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        if (pet == null)
                          const Text(
                            'No pet found - will create test pet for export',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _isTransferring ? null : () => _exportData(gameProvider),
                  icon: const Icon(Icons.file_download),
                  label: Text(pet == null
                      ? 'Create Test Pet & Export'
                      : 'Export to USB'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pet == null ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImportSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D4A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Importing will replace your current pet data!',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isTransferring ? null : _importData,
              icon: const Icon(Icons.file_upload),
              label: const Text('Import from USB'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      height: 300, // Fixed height for scrollable instructions
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D4A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionItem(
              '📱 Connect your device to computer via USB',
              Icons.usb,
            ),
            _buildInstructionItem(
              '📂 Enable file transfer mode on your device',
              Icons.settings,
            ),
            _buildInstructionItem(
              '💾 Export saves to Downloads/Desktop/Home folder',
              Icons.file_download,
            ),
            _buildInstructionItem(
              '📁 Import loads from any accessible folder',
              Icons.file_upload,
            ),
            _buildInstructionItem(
              '🔄 Data includes stats, items, achievements, and progress',
              Icons.sync,
            ),
            const SizedBox(height: 16),
            const Text(
              '🔐 HOW TO LOG IN:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildInstructionItem(
              '1️⃣ Open User Account screen',
              Icons.account_circle,
            ),
            _buildInstructionItem(
              '2️⃣ Enter your email and password',
              Icons.email,
            ),
            _buildInstructionItem(
              '3️⃣ Click "Sign In" to access cloud features',
              Icons.login,
            ),
            _buildInstructionItem(
              '4️⃣ New users can create free accounts',
              Icons.person_add,
            ),
            _buildInstructionItem(
              '5️⃣ Premium members get unlimited cloud storage',
              Icons.star,
            ),
            const SizedBox(height: 16),
            const Text(
              '📍 WHERE IS USER ACCOUNT SCREEN?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildInstructionItem(
              '🔝 Click the account icon (👤) in the top-right corner',
              Icons.account_circle,
            ),
            _buildInstructionItem(
              '📱 Or scroll down to "👤 USER ACCOUNT" section',
              Icons.arrow_downward,
            ),
            _buildInstructionItem(
              '⚡ Quick access: Tap the profile icon in app bar',
              Icons.touch_app,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'MACOS PERMISSION FIX',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInstructionItem(
                    'Move app to Applications folder',
                    Icons.folder,
                  ),
                  _buildInstructionItem(
                    'Grant Full Disk Access in System Preferences',
                    Icons.security,
                  ),
                  _buildInstructionItem(
                    'Try running from Terminal: open app.app',
                    Icons.terminal,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D4A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi,
                  color: _isWifiServer ? Colors.green : Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WiFi Status: $_wifiStatus',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_serverIP != null)
                      Text(
                        'Server: $_serverIP:8080',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isWifiServer ? _stopWifiServer : _startWifiServer,
                  icon: Icon(_isWifiServer ? Icons.stop : Icons.play_arrow),
                  label: Text(_isWifiServer ? 'Stop Server' : 'Start Server'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isWifiServer ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _connectToWifiServer(),
                  icon: const Icon(Icons.link),
                  label: const Text('Connect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          if (_isWifiServer) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🌐 Server is running!',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Other devices can connect to:\n$_serverIP:8080',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '💡 Make sure devices are on the same WiFi network',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startWifiServer() async {
    try {
      setState(() {
        _wifiStatus = 'Starting server...';
      });

      // Get local IP address using multiple methods
      String? wifiIP;

      // Method 1: Try network_info_plus
      try {
        final info = NetworkInfo();
        wifiIP = await info.getWifiIP();
      } catch (_) {}

      // Method 2: Try getting from network interfaces
      if (wifiIP == null) {
        try {
          final interfaces = await NetworkInterface.list(
              includeLoopback: false, type: InternetAddressType.any);
          for (final interface in interfaces) {
            for (final addr in interface.addresses) {
              if (addr.type == InternetAddressType.IPv4) {
                wifiIP = addr.address;
                break;
              }
            }
            if (wifiIP != null) break;
          }
        } catch (_) {}
      }

      // Method 3: Fallback to localhost for testing
      if (wifiIP == null) {
        wifiIP = '127.0.0.1';
      }

      // Start HTTP server
      _httpServer = await HttpServer.bind('0.0.0.0', 8080);

      setState(() {
        _isWifiServer = true;
        _wifiStatus = 'Server running';
        _serverIP = wifiIP;
        _statusMessage =
            '✅ WiFi server started!\nIP: $wifiIP:8080\nWaiting for connections...';
      });

      // Listen for connections
      await for (HttpRequest request in _httpServer!) {
        _handleWifiRequest(request);
      }
    } catch (e) {
      setState(() {
        _wifiStatus = 'Server failed';
        _statusMessage = '❌ Failed to start server: $e';
      });
    }
  }

  Future<void> _stopWifiServer() async {
    try {
      await _httpServer?.close();
      _httpServer = null;

      setState(() {
        _isWifiServer = false;
        _wifiStatus = 'Server stopped';
        _serverIP = null;
        _statusMessage = 'WiFi server stopped';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error stopping server: $e';
      });
    }
  }

  Future<void> _handleWifiRequest(HttpRequest request) async {
    try {
      if (request.method == 'GET') {
        // Serve pet data
        final gameProvider = context.read<GameProvider>();
        Pet? pet = gameProvider.pet;

        if (pet == null) {
          // Create test pet if none exists
          pet = Pet(name: 'WiFi Kitty', type: PetType.cat);
          pet.level = 5;
          pet.health = 100;
          pet.hunger = 80;
          pet.happiness = 90;
          pet.energy = 95;
          pet.intelligence = 60;
          pet.social = 70;
          pet.cleanliness = 100;
          pet.friendshipLevel = 25;
          pet.xp = 250;
          pet.coins = 100;
          pet.gems = 5;
          pet.currentAccessory = '';
          pet.accessories = ['collar', 'hat'];
          pet.achievements = ['first_pet', 'happy_pet'];
          pet.inventory = ['food', 'toy'];
          pet.skills = {'play': 3, 'feed': 2};
        }

        final exportData = {
          'version': '26.6',
          'timestamp': DateTime.now().toIso8601String(),
          'pet': {
            'name': pet.name,
            'type': pet.type.name,
            'level': pet.level,
            'health': pet.health,
            'hunger': pet.hunger,
            'happiness': pet.happiness,
            'energy': pet.energy,
            'intelligence': pet.intelligence,
            'social': pet.social,
            'cleanliness': pet.cleanliness,
            'friendshipLevel': pet.friendshipLevel,
            'xp': pet.xp,
            'coins': pet.coins,
            'gems': pet.gems,
            'currentAccessory': pet.currentAccessory,
            'accessories': pet.accessories,
            'achievements': pet.achievements,
            'inventory': pet.inventory,
            'skills': pet.skills,
          },
        };

        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(exportData));

        await request.response.close();

        setState(() {
          _lastTransferTime = DateTime.now().toString().substring(0, 19);
          _statusMessage =
              '✅ Pet data sent via WiFi!\nTo: ${request.requestedUri.host}\nTime: $_lastTransferTime';
        });
      } else {
        request.response.statusCode = HttpStatus.methodNotAllowed;
        await request.response.close();
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  Future<void> _connectToWifiServer() async {
    // Show dialog to enter server IP
    final controller = TextEditingController(text: '192.168.1.100:8080');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect to WiFi Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter server IP address:'),
            const SizedBox(height: 8),
            const Text(
              'Example: 192.168.1.100:8080',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '192.168.1.100:8080',
                border: OutlineInputBorder(),
                prefixText: 'http://',
                prefixStyle: TextStyle(color: Colors.grey),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            const Text(
              '💡 Make sure both devices are on the same WiFi network',
              style: TextStyle(color: Colors.blue, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final serverAddress = controller.text.trim();
              if (serverAddress.isNotEmpty) {
                Navigator.pop(context, serverAddress);
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _importFromWifi(result);
    }
  }

  Future<void> _importFromWifi(String serverAddress) async {
    try {
      // Validate server address
      if (serverAddress.isEmpty) {
        throw Exception('Server address is empty');
      }

      // Ensure the address has http:// prefix
      String fullAddress = serverAddress;
      if (!serverAddress.startsWith('http://') &&
          !serverAddress.startsWith('https://')) {
        fullAddress = 'http://$serverAddress';
      }

      setState(() {
        _isTransferring = true;
        _statusMessage = 'Connecting to WiFi server...\nAddress: $fullAddress';
      });

      final uri = Uri.parse(fullAddress);
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseData = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseData);

        if (data['pet'] != null) {
          final pet = Pet.fromJson(data['pet']);
          final gameProvider = context.read<GameProvider>();
          gameProvider.setPet(pet);

          setState(() {
            _statusMessage =
                '✅ Pet data imported via WiFi!\nPet: ${pet.name} (Level ${pet.level})\nFrom: $serverAddress';
            _lastTransferTime = DateTime.now().toString().substring(0, 19);
            _isTransferring = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Imported ${pet.name} (Level ${pet.level}) via WiFi'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          throw Exception('No pet data found in response');
        }
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      String errorMessage = e.toString();

      // Check for specific macOS permission errors
      if (errorMessage.contains('Operation not permitted') ||
          errorMessage.contains('errno = 1')) {
        errorMessage =
            'macOS Network Permission Error\n\n🔧 SOLUTION:\n1️⃣ System Preferences → Security & Privacy\n2️⃣ Firewall → Turn off "Block all incoming connections"\n3️⃣ Or add port 8080 to allowed apps\n4️⃣ Try using localhost (127.0.0.1) for testing';
      }

      setState(() {
        _statusMessage = '❌ WiFi import failed: $errorMessage';
        _isTransferring = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(
                child: Text(
                  errorMessage.contains('Operation not permitted')
                      ? 'Network permission denied'
                      : 'WiFi import failed',
                  maxLines: 2,
                ),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: errorMessage));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error copied to clipboard!'),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
          action: errorMessage.contains('Operation not permitted')
              ? SnackBarAction(
                  label: 'Fix Guide',
                  textColor: Colors.white,
                  onPressed: () {
                    _showNetworkPermissionGuide();
                  },
                )
              : null,
        ),
      );
    }
  }

  void _showNetworkPermissionGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔧 macOS Network Permission Fix'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'macOS is blocking the network connection. Follow these steps:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildStep('1️⃣', 'Open System Preferences'),
              _buildStep('2️⃣', 'Go to Security & Privacy'),
              _buildStep('3️⃣', 'Click Firewall'),
              _buildStep('4️⃣', 'Turn off "Block all incoming connections"'),
              _buildStep('5️⃣', 'OR: Click "Configure..." and add port 8080'),
              _buildStep('6️⃣', 'Restart the app and try again'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 ALTERNATIVE:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const Text(
                        'Use localhost (127.0.0.1:8080) for testing on the same device'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Try to open System Preferences
              Process.run('open', ['x-apple.systempreferences:Security']);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D4A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cloud Backup & Restore',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Automatic daily backups with cloud storage',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CloudBackupScreen()),
                    );
                  },
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Cloud Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CloudBackupScreen()),
                    );
                  },
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('Restore Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSharingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D4A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.share, color: Colors.purple),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pet Sharing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Share your pets with friends or accept shared pets',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PetSharingScreen()),
                );
              },
              icon: const Icon(Icons.pets),
              label: const Text('Pet Sharing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D4A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_circle, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Manage your account, premium features, and settings',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UserAccountScreen()),
                );
              },
              icon: const Icon(Icons.person),
              label: const Text('User Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(GameProvider gameProvider) async {
    setState(() {
      _isTransferring = true;
      _statusMessage = 'Preparing data for export...';
    });

    try {
      Pet? pet = gameProvider.pet;

      // If no pet exists, create a test pet
      if (pet == null) {
        pet = Pet(
          name: 'Test Kitty',
          type: PetType.cat,
        );

        // Set some test stats
        pet.level = 5;
        pet.health = 100;
        pet.hunger = 80;
        pet.happiness = 90;
        pet.energy = 95;
        pet.intelligence = 60;
        pet.social = 70;
        pet.cleanliness = 100;
        pet.friendshipLevel = 25;
        pet.xp = 250;
        pet.coins = 100;
        pet.gems = 5;
        pet.currentAccessory = '';
        pet.accessories = ['collar', 'hat'];
        pet.achievements = ['first_pet', 'happy_pet'];
        pet.inventory = ['food', 'toy'];
        pet.skills = {'play': 3, 'feed': 2};
      }

      // Create data package
      final exportData = {
        'version': '26.6',
        'timestamp': DateTime.now().toIso8601String(),
        'pet': {
          'name': pet.name,
          'type': pet.type.name,
          'level': pet.level,
          'health': pet.health,
          'hunger': pet.hunger,
          'happiness': pet.happiness,
          'energy': pet.energy,
          'intelligence': pet.intelligence,
          'social': pet.social,
          'cleanliness': pet.cleanliness,
          'friendshipLevel': pet.friendshipLevel,
          'xp': pet.xp,
          'coins': pet.coins,
          'gems': pet.gems,
          'currentAccessory': pet.currentAccessory,
          'accessories': pet.accessories,
          'achievements': pet.achievements,
          'inventory': pet.inventory,
          'skills': pet.skills,
        },
      };

      // Use system temp directory as the most reliable option
      // macOS apps have permission to write to temp directory
      Directory tempDir = Directory.systemTemp;
      Directory appTempDir = Directory('${tempDir.path}/pet_game_data');

      // Create app-specific temp directory
      try {
        if (!await appTempDir.exists()) {
          await appTempDir.create(recursive: true);
        }
      } catch (_) {
        // Fallback to system temp
        appTempDir = tempDir;
      }

      final downloadsDir = appTempDir;

      // Create filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'pet_data_${pet.name}_$timestamp.json';
      final file = File('${downloadsDir.path}/$filename');

      // Write data to file
      await file.writeAsString(jsonEncode(exportData));
      if (!mounted) return;

      setState(() {
        _statusMessage =
            '✅ Data exported successfully!\nFile: $filename\nLocation: ${downloadsDir.path}\n\n📁 HOW TO SAVE TO USB:\n1️⃣ Open Finder\n2️⃣ Press ⌘+Shift+G\n3️⃣ Paste: ${downloadsDir.path}\n4️⃣ Copy the .json file to your USB drive\n\n💡 Click status to copy path!';
        _lastTransferTime = DateTime.now().toString().substring(0, 19);
        _isTransferring = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(
                  child:
                      Text('Data exported to ${downloadsDir.path}/$filename')),
              IconButton(
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: '${downloadsDir.path}/$filename'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File path copied!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Open Finder',
            textColor: Colors.white,
            onPressed: () async {
              // Try to open Finder with the directory
              try {
                await Process.run('open', [downloadsDir.path]);
              } catch (e) {
                // Fallback: copy path to clipboard
                Clipboard.setData(ClipboardData(text: downloadsDir.path));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Path copied to clipboard! Use ⌘+Shift+G in Finder'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      final errorMessage =
          '❌ Export failed: ${e.toString()}\n\nTry: Move app to Applications folder or grant file permissions';
      setState(() {
        _statusMessage = errorMessage;
        _isTransferring = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(child: Text('Export failed: ${e.toString()}')),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: errorMessage));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error copied to clipboard!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isTransferring = true;
      _statusMessage = 'Searching for pet data files...';
    });

    try {
      // Try multiple directories for macOS compatibility
      late Directory downloadsDir;
      final homeDir = Platform.environment['HOME'];

      if (homeDir != null) {
        // Try actual user Downloads directory first
        downloadsDir = Directory('$homeDir/Downloads');

        // If Downloads doesn't exist, try Desktop
        if (!await downloadsDir.exists()) {
          downloadsDir = Directory('$homeDir/Desktop');
        }

        // If Desktop doesn't exist, try Documents
        if (!await downloadsDir.exists()) {
          downloadsDir = Directory('$homeDir/Documents');
        }

        // If Documents doesn't exist, try home directory
        if (!await downloadsDir.exists()) {
          downloadsDir = Directory(homeDir);
        }
      } else {
        // Fallback to current directory
        downloadsDir = Directory.current;
      }

      if (!await downloadsDir.exists()) {
        throw Exception('Cannot find accessible directory for import');
      }

      // Find all pet data files
      final files = await downloadsDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      if (files.isEmpty) {
        throw Exception(
            'No pet data files found. Check:\n• Downloads folder\n• Desktop\n• Home directory\n\nFile should end with .json');
      }

      // Get the most recent file
      files.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      final latestFile = files.first;

      // Read and parse data
      final content = await latestFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      // Validate data
      if (!data.containsKey('pet') || !data.containsKey('version')) {
        throw Exception('Invalid pet data format');
      }

      final petData = data['pet'] as Map<String, dynamic>;

      // Create pet from data
      final petType = PetType.values.firstWhere(
        (type) => type.name == petData['type'],
        orElse: () => PetType.cat,
      );

      final pet = Pet(
        id: petData['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: petData['name'] ?? 'Pet',
        type: petType,
      );

      // Update pet stats
      pet.level = petData['level'] ?? 1;
      pet.health = petData['health'] ?? 100;
      pet.hunger = petData['hunger'] ?? 50;
      pet.happiness = petData['happiness'] ?? 80;
      pet.energy = petData['energy'] ?? 100;
      pet.intelligence = petData['intelligence'] ?? 50;
      pet.social = petData['social'] ?? 50;
      pet.cleanliness = petData['cleanliness'] ?? 100;
      pet.friendshipLevel = petData['friendshipLevel'] ?? 0;
      pet.xp = petData['xp'] ?? 0;
      pet.coins = petData['coins'] ?? 0;
      pet.gems = petData['gems'] ?? 0;
      pet.currentAccessory = petData['currentAccessory'] ?? '';
      pet.accessories = List<String>.from(petData['accessories'] ?? []);
      pet.achievements = List<String>.from(petData['achievements'] ?? []);
      pet.inventory = List<String>.from(petData['inventory'] ?? []);
      pet.skills = Map<String, int>.from(petData['skills'] ?? {});

      // Update game provider
      final gameProvider = context.read<GameProvider>();
      gameProvider.setPet(pet);
      await gameProvider.saveGame();

      setState(() {
        _statusMessage =
            '✅ Data imported successfully!\nPet: ${pet.name} (Level ${pet.level})\nFrom: ${latestFile.path}';
        _lastTransferTime = DateTime.now().toString().substring(0, 19);
        _isTransferring = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${pet.name} (Level ${pet.level})'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      final errorMessage =
          '❌ Import failed: ${e.toString()}\n\nTry: Move app to Applications folder or grant file permissions';
      setState(() {
        _statusMessage = errorMessage;
        _isTransferring = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(child: Text('Import failed: ${e.toString()}')),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: errorMessage));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error copied to clipboard!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
