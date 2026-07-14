import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/update_service.dart';
import 'whats_new_dialog.dart';

class AppWrapper extends StatefulWidget {
  final Widget child;

  const AppWrapper({super.key, required this.child});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _shouldShowWhatsNew = false;

  @override
  void initState() {
    super.initState();
    _checkForNewVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForRemoteUpdate();
    });
  }

  void _checkForNewVersion() async {
    final prefs = await SharedPreferences.getInstance();

    const String currentVersion = UpdateService.currentVersion;
    final lastVersion = prefs.getString('lastWhatsNewVersion');

    if (lastVersion != currentVersion && mounted) {
      setState(() {
        _shouldShowWhatsNew = true;
      });
    }

    await prefs.setString('lastWhatsNewVersion', currentVersion);
  }

  Future<void> _checkForRemoteUpdate() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    await UpdateService.checkForUpdates(context);
  }

  void _closeWhatsNew() {
    setState(() {
      _shouldShowWhatsNew = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_shouldShowWhatsNew)
          Positioned.fill(
            child: Material(
              color: Colors.black54,
              child: WhatsNewDialog(onClose: _closeWhatsNew),
            ),
          ),
      ],
    );
  }
}
