import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../services/egg_nest_service.dart';
import '../services/sound_service.dart';

class EggNest extends StatefulWidget {
  final EggNestService service;
  final Future<void> Function(PetType species, String petId) onHatch;
  const EggNest({super.key, required this.service, required this.onHatch});
  @override
  State<EggNest> createState() => _EggNestState();
}

class _EggNestState extends State<EggNest> {
  PetType _species = PetType.cat;
  bool _busy = false;
  bool _loaded = false;
  String? _notice;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    widget.service.initialize().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted)
        setState(() => _notice =
            'Could not save the nest. Your egg is kept; please retry.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: widget.service,
      builder: (context, _) {
        if (!_loaded) return const Center(child: CircularProgressIndicator());
        final nest = widget.service;
        final egg = nest.egg;
        final seconds = (nest.remaining.inMilliseconds / 1000).ceil();
        final countdown =
            '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
        return ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Egg Nest',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
              egg == null
                  ? 'Choose a species and nurture a new friend. One free egg at a time; each takes 2 minutes.'
                  : '${egg.species.emoji} ${egg.species.name} egg',
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Center(
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: (egg?.species ?? _species)
                          .color
                          .withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: Text(nest.ready ? '🐣' : '🥚',
                      style: const TextStyle(fontSize: 72)))),
          const SizedBox(height: 20),
          if (egg == null) ...[
            DropdownButtonFormField<PetType>(
                initialValue: _species,
                isExpanded: true,
                decoration:
                    const InputDecoration(labelText: 'Choose your hatchling'),
                items: PetType.values
                    .map((type) => DropdownMenuItem(
                        value: type, child: Text('${type.emoji} ${type.name}')))
                    .toList(),
                onChanged:
                    _busy ? null : (type) => setState(() => _species = type!)),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                          await nest.start(_species);
                          SoundService().playSound('button_pop');
                        }),
                icon: const Icon(Icons.egg_outlined),
                label: const Text('Start egg · 2 minutes · Free')),
          ] else ...[
            LinearProgressIndicator(
                value: nest.progress,
                semanticsLabel: 'Egg incubation progress'),
            const SizedBox(height: 16),
            Text(nest.ready ? 'Ready to hatch!' : 'Hatches in $countdown',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'The timer keeps going when you leave. Enable cloud saving in your account to carry eggs across devices.',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: !nest.ready || _busy
                    ? null
                    : () => _run(() async {
                          await nest.hatch(widget.onHatch);
                          _notice =
                              '🐣 ${egg.species.name} joined your pet family!';
                          SoundService().playSound('reward');
                        }),
                icon: const Icon(Icons.pets),
                label: Text(nest.ready
                    ? 'Hatch & adopt ${egg.species.name}'
                    : 'Incubating…')),
          ],
          const SizedBox(height: 16),
          if (_notice != null)
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_notice!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
          const Text(
              'Hatched pets join your family and start at Day 1. Manage their name, care for them, and watch them grow.',
              textAlign: TextAlign.center),
        ]);
      });
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
