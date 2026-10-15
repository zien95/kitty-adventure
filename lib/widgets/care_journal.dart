import 'dart:async';

import 'package:flutter/material.dart';

import '../models/pet.dart';
import '../services/care_progress_service.dart';

/// A journal section suitable for a scrollable Hub tab or bottom sheet.
class CareJournal extends StatefulWidget {
  final List<Pet> pets;
  final CareProgressService service;
  final String? activePetId;
  final Future<void> Function(String petId, int coins) onReward;

  const CareJournal({
    super.key,
    required this.pets,
    required this.service,
    required this.onReward,
    this.activePetId,
  });

  @override
  State<CareJournal> createState() => _CareJournalState();
}

class _CareJournalState extends State<CareJournal> {
  Timer? _refreshTimer;
  bool _claiming = false;

  static const _labels = {
    'feed': 'FOOD',
    'play': 'TOY',
    'clean': 'CLEAN',
    'rest': 'SLEEP',
    'bond': 'BOND',
  };

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => widget.service.refresh(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _claim(
    String petId,
    Future<int> Function() claim, {
    bool birthday = false,
  }) async {
    if (_claiming) return;
    setState(() => _claiming = true);
    try {
      final coins = await claim();
      if (coins > 0) await widget.onReward(petId, coins);
      if (!mounted || coins <= 0) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(birthday
            ? '🎉 Happy birthday! +$coins coins for your pet.'
            : '🐾 Care checklist complete! +$coins coins.'),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not save this reward. Please try again.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.service,
        builder: (context, _) {
          if (!widget.service.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          if (widget.pets.isEmpty) {
            return const Text('Adopt a pet to start your care journal. 🐾');
          }
          final pet = widget.pets.firstWhere(
            (pet) => pet.id == widget.activePetId,
            orElse: () => widget.pets.first,
          );
          final progress = widget.service.progressFor(pet.id);
          final birthdays = widget.service.birthdaysFor(widget.pets);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _card(
                children: [
                  Text(
                    '${pet.name}’s Daily Care',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use FOOD, TOY, CLEAN, SLEEP, and BOND once today to fill '
                    'the checklist. Each pet has their own progress.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _labels.entries.map((entry) {
                      final done =
                          progress.completedActions.contains(entry.key);
                      return Chip(
                        avatar: Icon(
                          done ? Icons.check_circle : Icons.circle_outlined,
                          color: done ? Colors.green.shade700 : Colors.grey,
                          size: 18,
                        ),
                        label: Text(entry.value),
                        backgroundColor: done ? const Color(0xFFE6F4E8) : null,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.completedActions.length /
                        CareProgressService.careActions.length,
                    semanticsLabel: 'Daily care checklist',
                    semanticsValue:
                        '${progress.completedActions.length} of 5 completed',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: !_claiming && progress.canClaimDailyReward
                        ? () => _claim(pet.id,
                            () => widget.service.claimDailyReward(pet.id))
                        : null,
                    icon: Icon(progress.dailyRewardClaimed
                        ? Icons.check
                        : Icons.redeem),
                    label: Text(progress.dailyRewardClaimed
                        ? 'Today’s reward claimed'
                        : 'Claim ${CareProgressService.dailyRewardCoins} coins'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progress.comboRewardEarned
                        ? '✨ Care combo complete! +${CareProgressService.comboRewardCoins} coins earned today.'
                        : '✨ Care combo: ${progress.comboProgress}/3. Do 3 different checklist actions within 60 seconds for +${CareProgressService.comboRewardCoins} coins, once per pet each day.',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Birthday Calendar',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              const Text(
                'Celebrate on the anniversary of each pet’s adoption. '
                'Their first birthday is one year after adoption.',
              ),
              const SizedBox(height: 10),
              ...birthdays.map((birthday) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _birthdayCard(context, birthday),
                  )),
            ],
          );
        },
      );

  Widget _birthdayCard(BuildContext context, PetBirthday birthday) {
    final date =
        MaterialLocalizations.of(context).formatMediumDate(birthday.date);
    return _card(children: [
      Text(
        '${birthday.pet.type.emoji} ${birthday.pet.name}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 6),
      Text(birthday.isToday
          ? '🎂 Turns ${birthday.age} today!'
          : 'Turns ${birthday.age} on $date • in ${birthday.daysUntil} days'),
      if (birthday.pet.createdAt.month == 2 && birthday.pet.createdAt.day == 29)
        const Text('A leap-day pet: birthdays fall on February 29.'),
      if (birthday.isToday) ...[
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: !_claiming && birthday.canCelebrate
              ? () => _claim(
                    birthday.pet.id,
                    () => widget.service.celebrateBirthday(birthday.pet),
                    birthday: true,
                  )
              : null,
          icon: Icon(birthday.celebrated ? Icons.check : Icons.celebration),
          label: Text(birthday.celebrated
              ? 'Birthday celebrated!'
              : 'Celebrate +${CareProgressService.birthdayRewardCoins} coins'),
        ),
      ],
    ]);
  }

  Widget _card({required List<Widget> children}) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
}
