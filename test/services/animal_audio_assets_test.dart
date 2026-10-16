import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const species = [
    'cat',
    'dog',
    'bunny',
    'fox',
    'panda',
    'bird',
    'elephant',
  ];
  const folders = [
    'assets/sounds',
    'assets/sounds/cute',
    'assets/sounds/soft',
    'assets/sounds/arcade',
  ];

  test('real-animal WAV files are valid, audible, and unclipped', () async {
    for (final animal in species) {
      final base = await File('assets/sounds/pet_$animal.wav').readAsBytes();
      for (final folder in folders) {
        final bytes = await File('$folder/pet_$animal.wav').readAsBytes();
        expect(bytes, base, reason: '$folder should use the real $animal clip');
        _expectHealthyWav(bytes, '$folder/pet_$animal.wav');
      }
    }

    final cat = await File('assets/sounds/pet_cat.wav').readAsBytes();
    for (final folder in folders) {
      expect(await File('$folder/cat_meow.wav').readAsBytes(), cat);
    }
  });

  test('credit document covers every animal and license family', () async {
    final credits = await File('THIRD_PARTY_AUDIO.md').readAsString();
    for (final animal in species) {
      expect(credits.toLowerCase(),
          contains('| ${animal == 'bunny' ? 'bunny' : animal} |'));
    }
    expect(credits, contains('CC0 1.0'));
    expect(credits, contains('CC BY 4.0'));
    expect(credits, contains('CC BY-SA 4.0'));
    expect(credits, contains('Public domain'));
  });
}

void _expectHealthyWav(List<int> bytes, String name) {
  expect(bytes.length, greaterThan(44), reason: name);
  expect(ascii.decode(bytes.sublist(0, 4)), 'RIFF', reason: name);
  expect(ascii.decode(bytes.sublist(8, 12)), 'WAVE', reason: name);

  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  expect(data.getUint16(22, Endian.little), 1, reason: '$name must be mono');
  expect(data.getUint32(24, Endian.little), 44100, reason: '$name sample rate');
  expect(data.getUint16(34, Endian.little), 16, reason: '$name bit depth');

  var audible = 0;
  var peak = 0;
  for (var offset = 44; offset + 1 < bytes.length; offset += 2) {
    final sample = data.getInt16(offset, Endian.little).abs();
    if (sample > 128) audible++;
    if (sample > peak) peak = sample;
  }
  expect(audible, greaterThan(4410), reason: '$name should not be silent');
  expect(peak, inInclusiveRange(10000, 32766), reason: '$name peak level');
}
