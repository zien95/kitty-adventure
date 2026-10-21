import 'package:flutter_test/flutter_test.dart';
import 'package:zona_pets/services/update_service.dart';

void main() {
  group('Tauri mobile URL detection', () {
    test('accepts the explicit mobile-shell marker', () {
      expect(
        UpdateService.isTauriMobileUrl(
          Uri.parse('https://pet-fiasco.web.app/?tauri-mobile=1'),
        ),
        isTrue,
      );
    });

    test('does not hide downloads on the ordinary website', () {
      expect(
        UpdateService.isTauriMobileUrl(
          Uri.parse('https://pet-fiasco.web.app/'),
        ),
        isFalse,
      );
      expect(
        UpdateService.isTauriMobileUrl(
          Uri.parse('https://pet-fiasco.web.app/?tauri-mobile=0'),
        ),
        isFalse,
      );
    });
  });

  group('update version comparison', () {
    test('recognizes newer releases and ignores build metadata', () {
      expect(UpdateService.isVersionNewer('26.10.1', '26.10.0'), isTrue);
      expect(
          UpdateService.isVersionNewer('v26.11.0+261100', '26.10.9'), isTrue);
      expect(UpdateService.isVersionNewer('26.10.0+9', '26.10.0+1'), isFalse);
    });
  });
}
