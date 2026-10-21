import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../gameplay/pet_world_simulation.dart';
import '../models/pet.dart';

class ThirdPersonPetWorld extends StatefulWidget {
  const ThirdPersonPetWorld({
    super.key,
    required this.pet,
    required this.petAgeAsset,
    required this.petMoodAsset,
    required this.moodAtlasRows,
    required this.reactionAnimation,
    required this.onEat,
    required this.onPetTap,
    required this.onPetSecret,
    this.companionPets = const [],
    this.onSelectPet,
    this.onClean,
    this.onRest,
    this.onPlay,
    this.onTrain,
    this.onBond,
    this.onVet,
    this.onOpenGames,
    this.reactionMessage,
    this.accessoryEmoji = '',
  });

  final Pet pet;
  final String petAgeAsset;
  final String petMoodAsset;
  final int moodAtlasRows;
  final Animation<double> reactionAnimation;
  final VoidCallback onEat;
  final VoidCallback onPetTap;
  final VoidCallback onPetSecret;
  final List<Pet> companionPets;
  final ValueChanged<Pet>? onSelectPet;
  final VoidCallback? onClean;
  final VoidCallback? onRest;
  final VoidCallback? onPlay;
  final VoidCallback? onTrain;
  final VoidCallback? onBond;
  final VoidCallback? onVet;
  final VoidCallback? onOpenGames;
  final String? reactionMessage;
  final String accessoryEmoji;

  @override
  State<ThirdPersonPetWorld> createState() => _ThirdPersonPetWorldState();
}

class _ThirdPersonPetWorldState extends State<ThirdPersonPetWorld>
    with SingleTickerProviderStateMixin {
  late PetWorldSimulation _world;
  late final Ticker _ticker;
  final FocusNode _focusNode = FocusNode(debugLabel: '3D pet controls');
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  Duration? _lastTick;
  Offset _mobileMovement = Offset.zero;
  double _cameraX = 0;
  double _cameraZ = 0;
  double _walkPhase = 0;
  bool _facingLeft = false;
  String _status = 'Find the food bowl';

  bool get _isBird => widget.pet.type == PetType.bird;

  @override
  void initState() {
    super.initState();
    _world = PetWorldSimulation(canFly: _isBird);
    _ticker = createTicker(_tick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant ThirdPersonPetWorld oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pet.id != widget.pet.id ||
        oldWidget.pet.type != widget.pet.type) {
      final previousWorld = _world;
      _world = PetWorldSimulation(
        canFly: _isBird,
        x: previousWorld.x,
        y: _isBird ? previousWorld.y : 0,
        z: previousWorld.z,
        cameraYaw: previousWorld.cameraYaw,
      );
      _status = _isBird
          ? '${widget.pet.name} selected • ready to fly'
          : '${widget.pet.name} selected • ready to explore';
      _pressedKeys.clear();
      _mobileMovement = Offset.zero;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final previous = _lastTick;
    _lastTick = elapsed;
    if (previous == null || !mounted) return;
    final dt =
        (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;

    final keyboardForward = (_down(LogicalKeyboardKey.keyW) ||
                _down(LogicalKeyboardKey.arrowUp)
            ? 1.0
            : 0.0) -
        (_down(LogicalKeyboardKey.keyS) || _down(LogicalKeyboardKey.arrowDown)
            ? 1.0
            : 0.0);
    final keyboardRight = (_down(LogicalKeyboardKey.keyD) ? 1.0 : 0.0) -
        (_down(LogicalKeyboardKey.keyA) ? 1.0 : 0.0);
    final forward = (keyboardForward - _mobileMovement.dy).clamp(-1.0, 1.0);
    final right = (keyboardRight + _mobileMovement.dx).clamp(-1.0, 1.0);
    final turn = (_down(LogicalKeyboardKey.arrowRight) ? 1.0 : 0.0) -
        (_down(LogicalKeyboardKey.arrowLeft) ? 1.0 : 0.0);
    final moving = forward.abs() + right.abs() > 0.02;
    if (moving) {
      _walkPhase += dt * (_isBird ? 11 : 8);
      if (right.abs() > 0.05) _facingLeft = right < 0;
    }

    final events = _world.step(
      dt: dt,
      forward: forward,
      right: right,
      turn: turn,
      ascend: _isBird && _down(LogicalKeyboardKey.space),
      descend: _isBird &&
          (_down(LogicalKeyboardKey.shiftLeft) ||
              _down(LogicalKeyboardKey.shiftRight) ||
              _down(LogicalKeyboardKey.keyQ)),
    );
    _updateFollowCamera();
    if (events.contains(PetWorldEvent.ateFood)) {
      _status = '${widget.pet.name} reached dinner!';
      widget.onEat();
    } else if (_world.onFoodBowl) {
      _status = '${widget.pet.name} is eating at the bowl';
    } else if (_world.nearFood) {
      _status = _isBird
          ? 'Fly low over the bowl to eat'
          : 'Keep walking into the bowl to eat';
    } else if (_isBird && _world.y > 0.2) {
      _status = 'Flying at Y ${_world.y.toStringAsFixed(1)}';
    } else {
      final landmark = _world.nearestLandmark;
      _status = _world.actionableLandmark != null
          ? '${landmark.symbol} ${landmark.label}: '
              '${landmark.actionLabel} with E / ACTION'
          : 'Bowl ${_world.distanceToFood.toStringAsFixed(1)}m away';
    }
    setState(() {});
  }

  void _updateFollowCamera() {
    final deltaX = _world.x - _cameraX;
    final deltaZ = _world.z - _cameraZ;
    final cosine = math.cos(_world.cameraYaw);
    final sine = math.sin(_world.cameraYaw);
    final right = cosine * deltaX - sine * deltaZ;
    final forward = sine * deltaX + cosine * deltaZ;

    // Keep the scenery still while the pet crosses the useful center of the
    // screen. The camera only scrolls once the pet reaches this view-space
    // dead zone, which keeps a large world navigable without pinning the pet.
    final cameraShiftRight = switch (right) {
      > 3.0 => right - 3.0,
      < -3.0 => right + 3.0,
      _ => 0.0,
    };
    final cameraShiftForward = switch (forward) {
      > 6.0 => forward - 6.0,
      < -2.5 => forward + 2.5,
      _ => 0.0,
    };
    _cameraX += cosine * cameraShiftRight + sine * cameraShiftForward;
    _cameraZ += -sine * cameraShiftRight + cosine * cameraShiftForward;
  }

  double get _cameraHeight => 2.75 + math.max(0.0, _world.y - 1.4) * 0.9;

  bool _down(LogicalKeyboardKey key) => _pressedKeys.contains(key);

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!_handledKey(event.logicalKey)) return KeyEventResult.ignored;
    final wasPressed = _pressedKeys.contains(event.logicalKey);
    if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    } else {
      _pressedKeys.add(event.logicalKey);
      if (!wasPressed && event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.space) {
          _world.jumpOrFlap();
        } else if (event.logicalKey == LogicalKeyboardKey.keyE) {
          _doAction();
        }
      }
    }
    return KeyEventResult.handled;
  }

  bool _handledKey(LogicalKeyboardKey key) => {
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.space,
        LogicalKeyboardKey.shiftLeft,
        LogicalKeyboardKey.shiftRight,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
      }.contains(key);

  void _doAction() {
    final result = _world.performAction();
    if (result == null) {
      final nearest = _world.nearestLandmark;
      final placeDistance = _world.distanceToLandmark(nearest);
      _status = placeDistance < _world.distanceToFood
          ? 'Move closer to ${nearest.symbol} ${nearest.label}'
          : 'Move closer to the food bowl';
    } else if (result.isFoodBowl) {
      _status = _isBird ? 'Diving for dinner!' : 'Jumping for dinner!';
    } else {
      final landmark = result.landmark!;
      _status = landmark.arrivalMessage;
      _runLandmarkAction(landmark.kind);
    }
    _focusNode.requestFocus();
    setState(() {});
  }

  void _runLandmarkAction(PetWorldLandmarkKind kind) {
    switch (kind) {
      case PetWorldLandmarkKind.pond:
        widget.onClean?.call();
      case PetWorldLandmarkKind.cottage:
        widget.onBond?.call();
      case PetWorldLandmarkKind.scratchingTree:
        widget.onTrain?.call();
      case PetWorldLandmarkKind.playPark:
      case PetWorldLandmarkKind.toyYard:
        widget.onPlay?.call();
      case PetWorldLandmarkKind.flowerGarden:
        widget.onBond?.call();
      case PetWorldLandmarkKind.vetClinic:
        widget.onVet?.call();
      case PetWorldLandmarkKind.petBed:
        widget.onRest?.call();
      case PetWorldLandmarkKind.gameStation:
        widget.onOpenGames?.call();
    }
  }

  void _rotateCamera(double delta) {
    _world.cameraYaw += delta;
    _focusNode.requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final compact = size.width < 760;
          final petProjection = _project(
            size,
            _world.x,
            _world.y,
            _world.z,
          );
          final groundProjection = _project(
            size,
            _world.x,
            0,
            _world.z,
          );
          final bowlProjection = _project(
            size,
            PetWorldSimulation.foodX,
            0,
            PetWorldSimulation.foodZ,
          );
          final placeProjections = [
            for (final landmark in PetWorldSimulation.landmarks)
              _WorldPlaceProjection(
                landmark: landmark,
                projection: _project(size, landmark.x, 0, landmark.z),
              ),
          ]
            ..removeWhere((place) => !place.projection.visible)
            ..sort(
              (a, b) => a.projection.scale.compareTo(b.projection.scale),
            );
          final visibleCompanions = widget.companionPets
              .where(
                (pet) =>
                    !identical(pet, widget.pet) &&
                    (pet.id.isEmpty || pet.id != widget.pet.id),
              )
              .toList();
          final companionProjections = <_CompanionProjection>[];
          final cosine = math.cos(_world.cameraYaw);
          final sine = math.sin(_world.cameraYaw);
          for (var index = 0; index < visibleCompanions.length; index++) {
            final column = index % 4;
            final row = index ~/ 4;
            final sideOffset = (column - 1.5) * 1.12;
            final forwardOffset = 1.15 + row * 1.25;
            final companionX =
                _world.x + cosine * sideOffset + sine * forwardOffset;
            final companionZ =
                _world.z - sine * sideOffset + cosine * forwardOffset;
            companionProjections.add(
              _CompanionProjection(
                pet: visibleCompanions[index],
                index: index,
                projection: _project(size, companionX, 0, companionZ),
              ),
            );
          }

          return Semantics(
            label:
                'Third person 3D pet yard. X ${_world.x.toStringAsFixed(1)}, '
                'Y ${_world.y.toStringAsFixed(1)}, Z ${_world.z.toStringAsFixed(1)}.',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _focusNode.requestFocus,
              onHorizontalDragUpdate: (details) =>
                  _rotateCamera(-details.delta.dx * 0.009),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PerspectiveYardPainter(
                        cameraX: _cameraX,
                        cameraHeight: _cameraHeight,
                        cameraZ: _cameraZ,
                        cameraYaw: _world.cameraYaw,
                        darkMode:
                            Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                  ),
                  for (final place in placeProjections)
                    _buildWorldPlace(place, compact),
                  if (bowlProjection.visible)
                    _buildFoodBowl(bowlProjection, compact),
                  for (final companion in companionProjections)
                    if (companion.projection.visible)
                      _buildCompanionPet(companion, compact),
                  if (groundProjection.visible)
                    Positioned(
                      left: groundProjection.point.dx - 58,
                      top: groundProjection.point.dy - 13,
                      width: 116,
                      height: 26,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: (0.34 - _world.y * 0.035).clamp(0.08, 0.34),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF173C43),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (petProjection.visible) _buildPet(petProjection, compact),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _coordinateHud(),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _miniMap(compact),
                  ),
                  Positioned(
                    left: 10,
                    top: compact ? 116 : 132,
                    child: _statusHud(),
                  ),
                  if (compact) ...[
                    Positioned(
                      left: 14,
                      bottom: 12,
                      child: _mobileJoystick(),
                    ),
                    Positioned(
                      right: 14,
                      bottom: 12,
                      child: _mobileActions(),
                    ),
                  ] else
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 10,
                      child: Center(child: _desktopHint()),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoodBowl(_Projection projection, bool compact) {
    final scale = projection.scale.clamp(0.46, 1.15);
    final width = (compact ? 82.0 : 104.0) * scale;
    final height = width * 0.66;
    return Positioned(
      key: const ValueKey('world-food-bowl-position'),
      left: projection.point.dx - width / 2,
      top: projection.point.dy - height * 0.78,
      width: width,
      height: height + 36,
      child: IgnorePointer(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _world.nearFood
                    ? const Color(0xFFFFD45E)
                    : const Color(0xE61C2940),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _world.nearFood
                    ? (_isBird ? 'LAND TO EAT' : 'WALK IN TO EAT')
                    : 'BOWL',
                style: TextStyle(
                  color:
                      _world.nearFood ? const Color(0xFF503B16) : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(-0.30),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFB95E), Color(0xFFCC5C45)],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.elliptical(80, 25),
                      bottom: Radius.circular(22),
                    ),
                    border:
                        Border.all(color: const Color(0xFF6B3441), width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 8,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🥣', style: TextStyle(fontSize: 28)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorldPlace(_WorldPlaceProjection place, bool compact) {
    final projection = place.projection;
    final landmark = place.landmark;
    final scale = projection.scale.clamp(0.22, 1.18);
    final width = (compact ? 122.0 : 154.0) * scale;
    final height = width * 0.88;
    final actionable = identical(_world.actionableLandmark, landmark);
    return Positioned(
      key: ValueKey('world-place-${landmark.kind.name}'),
      left: projection.point.dx - width / 2,
      top: projection.point.dy - height * 0.83,
      width: width,
      height: height,
      child: IgnorePointer(
        child: Semantics(
          label: '${landmark.label}. ${landmark.actionLabel}.',
          child: Column(
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: width),
                padding: EdgeInsets.symmetric(
                  horizontal: (7 * scale).clamp(3, 8),
                  vertical: (3 * scale).clamp(2, 4),
                ),
                decoration: BoxDecoration(
                  color: actionable
                      ? const Color(0xFFFFD45E)
                      : const Color(0xE61C2940),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: actionable ? Colors.white : const Color(0x779FD8FF),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    actionable
                        ? '${landmark.symbol} ${landmark.actionLabel}: ${landmark.label}'
                        : '${landmark.symbol} ${landmark.label}',
                    maxLines: 1,
                    style: TextStyle(
                      color:
                          actionable ? const Color(0xFF503B16) : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: CustomPaint(
                  painter: _WorldPlacePainter(
                    kind: landmark.kind,
                    accent: _landmarkColor(landmark.kind),
                    highlighted: actionable,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPet(_Projection projection, bool compact) {
    final width = (compact ? 116.0 : 176.0) * projection.scale.clamp(0.8, 1.1);
    final height = width * 1.06;
    final walkingBob = math.sin(_walkPhase) * (_isBird ? 3.5 : 2.0);
    final stageScale = switch (widget.pet.evolutionStage) {
      EvolutionStage.baby => 0.72,
      EvolutionStage.child => 0.82,
      EvolutionStage.teen => 0.91,
      EvolutionStage.adult => 1.0,
      EvolutionStage.elder => 1.08,
    };
    return Positioned(
      key: const ValueKey('world-pet-position'),
      left: projection.point.dx - width / 2,
      top: projection.point.dy - height - walkingBob,
      width: width,
      height: height,
      child: AnimatedBuilder(
        animation: widget.reactionAnimation,
        builder: (context, child) {
          final reaction = math.sin(widget.reactionAnimation.value * math.pi);
          return Transform.translate(
            offset: Offset(0, -reaction * 22),
            child: Transform.scale(
              alignment: Alignment.bottomCenter,
              scale: stageScale + reaction * 0.06,
              child: child,
            ),
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            GestureDetector(
              onTap: () {
                _focusNode.requestFocus();
                widget.onPetTap();
              },
              onDoubleTap: widget.onPetSecret,
              onLongPress: widget.onPetSecret,
              child: Transform.flip(
                flipX: _facingLeft,
                child: _PetSprite(
                  pet: widget.pet,
                  ageAsset: widget.petAgeAsset,
                  moodAsset: widget.petMoodAsset,
                  moodAtlasRows: widget.moodAtlasRows,
                  width: width,
                  height: height,
                ),
              ),
            ),
            if (widget.accessoryEmoji.isNotEmpty)
              Positioned(
                top: 4,
                right: 8,
                child: Text(
                  widget.accessoryEmoji,
                  style: TextStyle(fontSize: (width * 0.15).clamp(16, 28)),
                ),
              ),
            Positioned(
              top: 6,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xE6FFFFFF),
                  shape: BoxShape.circle,
                ),
                child: Text(widget.pet.moodEmoji),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xE6FFD45E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    'SELECTED • ${widget.pet.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF503B16),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.reactionMessage != null)
              Positioned(
                left: -20,
                right: -20,
                bottom: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xEEFFFFFF),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: widget.pet.type.color, width: 2),
                  ),
                  child: Text(
                    widget.reactionMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF263349),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanionPet(
    _CompanionProjection companion,
    bool compact,
  ) {
    final pet = companion.pet;
    final projection = companion.projection;
    final width = (compact ? 70.0 : 98.0) * projection.scale.clamp(0.70, 1.0);
    final height = width * 1.06;
    final bob = math.sin(_walkPhase * 0.65 + companion.index) * 1.3;
    final ageAsset = 'assets/images/pet_3d_age_${pet.type.name}_v26_10.png';
    final moodAsset = 'assets/images/pet_3d_moods_${pet.type.name}_v26_10.png';
    final moodRows = pet.type == PetType.dog || pet.type == PetType.fox ? 1 : 5;

    return Positioned(
      key: ValueKey(
        'world-companion-${pet.id.isEmpty ? '${pet.type.name}-${companion.index}' : pet.id}',
      ),
      left: projection.point.dx - width / 2,
      top: projection.point.dy - height - bob,
      width: width,
      height: height + 18,
      child: Semantics(
        button: true,
        label: 'Select ${pet.name}, ${pet.type.name}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _focusNode.requestFocus();
            widget.onSelectPet?.call(pet);
          },
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 15,
                child: Container(
                  width: width * 0.62,
                  height: width * 0.13,
                  decoration: BoxDecoration(
                    color: const Color(0x55173C43),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: Transform.flip(
                  flipX: companion.index.isOdd,
                  child: _PetSprite(
                    pet: pet,
                    ageAsset: ageAsset,
                    moodAsset: moodAsset,
                    moodAtlasRows: moodRows,
                    width: width,
                    height: height,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  constraints: BoxConstraints(maxWidth: width),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xE61C2940),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: pet.type.color, width: 1.5),
                  ),
                  child: Text(
                    'TAP • ${pet.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coordinateHud() {
    Text line(String axis, double value, Color color) => Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$axis  ',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
              TextSpan(text: _signed(value)),
            ],
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        );

    return Container(
      key: const ValueKey('world-coordinate-hud'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xD9182438),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xAA9FD8FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '3RD PERSON • XYZ',
            style: TextStyle(
              color: Color(0xFFDAEEFF),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          line('X', _world.x, const Color(0xFFFF6B7A)),
          line('Y', _world.y, const Color(0xFF72E6A5)),
          line('Z', _world.z, const Color(0xFF68B9FF)),
        ],
      ),
    );
  }

  String _signed(double value) =>
      '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}';

  Widget _miniMap(bool compact) {
    return Container(
      key: const ValueKey('world-mini-map'),
      width: compact ? 112 : 142,
      height: compact ? 98 : 114,
      padding: const EdgeInsets.fromLTRB(7, 5, 7, 7),
      decoration: BoxDecoration(
        color: const Color(0xD9182438),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xAA9FD8FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WORLD MAP • E / ACTION',
            style: TextStyle(
              color: Color(0xFFDAEEFF),
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: CustomPaint(
              painter: _WorldMiniMapPainter(
                playerX: _world.x,
                playerZ: _world.z,
                cameraYaw: _world.cameraYaw,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusHud() {
    return IgnorePointer(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 230),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xD9FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.pet.type.color, width: 2),
        ),
        child: Text(
          '🎯 $_status',
          style: const TextStyle(
            color: Color(0xFF263349),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _desktopHint() {
    final flight = _isBird ? 'SPACE fly up • SHIFT/Q fly down' : 'SPACE jump';
    return Container(
      key: const ValueKey('desktop-3d-controls'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xD91A2638),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0x889FD8FF)),
      ),
      child: Text(
        'WASD move • ← → camera • walk into bowl • $flight • '
        'E enter/action • drag to look',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _mobileJoystick() {
    const size = 104.0;
    return Semantics(
      label: 'Movement joystick',
      child: GestureDetector(
        key: const ValueKey('mobile-move-control'),
        onPanStart: (details) => _updateJoystick(details.localPosition, size),
        onPanUpdate: (details) => _updateJoystick(details.localPosition, size),
        onPanEnd: (_) => setState(() => _mobileMovement = Offset.zero),
        onPanCancel: () => setState(() => _mobileMovement = Offset.zero),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0x661A2638),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xBBFFFFFF), width: 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Text(
                'MOVE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Transform.translate(
                offset: _mobileMovement * 31,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xE670B8FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateJoystick(Offset local, double size) {
    final delta = local - Offset(size / 2, size / 2);
    final scaled = delta / (size * 0.36);
    final distance = scaled.distance;
    setState(() {
      _mobileMovement = distance > 1 ? scaled / distance : scaled;
    });
    _focusNode.requestFocus();
  }

  Widget _mobileActions() {
    Widget button({
      required Key key,
      required String label,
      required IconData icon,
      required VoidCallback onPressed,
      Color color = const Color(0xFF7D6BEF),
    }) {
      return Semantics(
        button: true,
        label: label,
        child: FilledButton(
          key: key,
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.92),
            foregroundColor: Colors.white,
            minimumSize: const Size(76, 42),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Colors.white, width: 2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              Text(
                label,
                style:
                    const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isBird)
          button(
            key: const ValueKey('mobile-fly-down'),
            label: 'FLY DOWN',
            icon: Icons.arrow_downward,
            color: const Color(0xFF4D8FB8),
            onPressed: () {
              _world.verticalVelocity = -3.2;
              _focusNode.requestFocus();
            },
          ),
        if (_isBird) const SizedBox(height: 6),
        button(
          key: const ValueKey('mobile-jump-fly'),
          label: _isBird ? 'FLY UP' : 'JUMP',
          icon: _isBird ? Icons.flight_takeoff : Icons.arrow_upward,
          onPressed: () {
            _world.jumpOrFlap();
            _focusNode.requestFocus();
          },
        ),
        const SizedBox(height: 6),
        button(
          key: const ValueKey('mobile-world-action'),
          label: _worldActionLabel,
          icon: _world.nearFood ? Icons.restaurant : Icons.touch_app,
          color: const Color(0xFFEE7B66),
          onPressed: _doAction,
        ),
      ],
    );
  }

  String get _worldActionLabel {
    if (_world.nearFood) return 'EAT';
    final landmark = _world.actionableLandmark;
    return landmark?.actionLabel ?? 'ACTION';
  }

  _Projection _project(
    Size size,
    double worldX,
    double worldY,
    double worldZ,
  ) {
    const cameraDistance = 5.4;
    final relativeX = worldX - _cameraX;
    final relativeZ = worldZ - _cameraZ;
    final cosine = math.cos(_world.cameraYaw);
    final sine = math.sin(_world.cameraYaw);
    final right = cosine * relativeX - sine * relativeZ;
    final forward = sine * relativeX + cosine * relativeZ;
    final depth = cameraDistance + forward;
    if (depth <= 0.55) return const _Projection.hidden();
    final focal = size.height * 1.06;
    final horizon = size.height * 0.27;
    return _Projection(
      point: Offset(
        size.width / 2 + right * focal / depth,
        horizon + (_cameraHeight - worldY) * focal / depth,
      ),
      scale: cameraDistance / depth,
    );
  }
}

class _PetSprite extends StatelessWidget {
  const _PetSprite({
    required this.pet,
    required this.ageAsset,
    required this.moodAsset,
    required this.moodAtlasRows,
    required this.width,
    required this.height,
  });

  final Pet pet;
  final String ageAsset;
  final String moodAsset;
  final int moodAtlasRows;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final useAgeStrip = pet.currentMood == PetMood.happy;
    final asset = useAgeStrip ? ageAsset : moodAsset;
    final columns =
        useAgeStrip ? EvolutionStage.values.length : PetMood.values.length;
    final rows = useAgeStrip ? 1 : moodAtlasRows;
    final column =
        useAgeStrip ? pet.evolutionStage.index : pet.currentMood.index;
    final row = useAgeStrip || rows == 1 ? 0 : pet.evolutionStage.index;
    final sourceCellAspect = useAgeStrip
        ? 0.60
        : rows == 1
            ? 0.375
            : 1.0;
    final cellWidth = math.min(width, height * sourceCellAspect);
    final cellHeight = math.min(height, cellWidth / sourceCellAspect);

    return Semantics(
      image: true,
      label: '${pet.stageName} ${pet.type.name}, ${pet.currentMood.name} mood',
      child: SizedBox(
        key: ValueKey(
          'pet-sprite-${pet.type.name}-${pet.evolutionStage.name}-${pet.currentMood.name}',
        ),
        width: width,
        height: height,
        child: Center(
          child: SizedBox(
            width: cellWidth,
            height: cellHeight,
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: -column * cellWidth,
                    top: -row * cellHeight,
                    width: cellWidth * columns,
                    height: cellHeight * rows,
                    child: Image.asset(
                      asset,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Projection {
  const _Projection({required this.point, required this.scale})
      : visible = true;
  const _Projection.hidden()
      : point = Offset.zero,
        scale = 0,
        visible = false;

  final Offset point;
  final double scale;
  final bool visible;
}

class _WorldPlaceProjection {
  const _WorldPlaceProjection({
    required this.landmark,
    required this.projection,
  });

  final PetWorldLandmark landmark;
  final _Projection projection;
}

class _CompanionProjection {
  const _CompanionProjection({
    required this.pet,
    required this.index,
    required this.projection,
  });

  final Pet pet;
  final int index;
  final _Projection projection;
}

class _WorldPlacePainter extends CustomPainter {
  const _WorldPlacePainter({
    required this.kind,
    required this.accent,
    required this.highlighted,
  });

  final PetWorldLandmarkKind kind;
  final Color accent;
  final bool highlighted;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawOval(
      Rect.fromLTWH(w * 0.08, h * 0.77, w * 0.84, h * 0.18),
      Paint()
        ..color =
            highlighted ? const Color(0xAAFFD45E) : const Color(0x66152F35),
    );
    if (highlighted) {
      canvas.drawOval(
        Rect.fromLTWH(w * 0.05, h * 0.73, w * 0.90, h * 0.25),
        Paint()
          ..color = const Color(0xFFFFE37E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2, w * 0.025),
      );
    }

    switch (kind) {
      case PetWorldLandmarkKind.pond:
        _paintPond(canvas, size);
      case PetWorldLandmarkKind.cottage:
        _paintCottage(canvas, size);
      case PetWorldLandmarkKind.scratchingTree:
        _paintTree(canvas, size);
      case PetWorldLandmarkKind.playPark:
        _paintPark(canvas, size);
      case PetWorldLandmarkKind.flowerGarden:
        _paintGarden(canvas, size);
      case PetWorldLandmarkKind.vetClinic:
        _paintVet(canvas, size);
      case PetWorldLandmarkKind.petBed:
        _paintBed(canvas, size);
      case PetWorldLandmarkKind.toyYard:
        _paintToys(canvas, size);
      case PetWorldLandmarkKind.gameStation:
        _paintGameStation(canvas, size);
    }
  }

  void _paintPond(Canvas canvas, Size size) {
    final pond = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.42,
      size.width * 0.84,
      size.height * 0.43,
    );
    canvas.drawOval(pond, Paint()..color = const Color(0xFF65CFF0));
    canvas.drawOval(
      pond,
      Paint()
        ..color = const Color(0xFF287A9B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, size.width * 0.025),
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.39,
        size.height * 0.50,
        size.width * 0.25,
        size.height * 0.14,
      ),
      Paint()..color = const Color(0xFFFFE38A),
    );
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.48),
      size.width * 0.07,
      Paint()..color = const Color(0xFFFFE38A),
    );
    canvas.drawCircle(
      Offset(size.width * 0.64, size.height * 0.46),
      size.width * 0.012,
      Paint()..color = const Color(0xFF223047),
    );
    final reedPaint = Paint()
      ..color = const Color(0xFF3C9B62)
      ..strokeWidth = math.max(1.5, size.width * 0.018)
      ..strokeCap = StrokeCap.round;
    for (final x in [0.16, 0.23, 0.78, 0.84]) {
      canvas.drawLine(
        Offset(size.width * x, size.height * 0.67),
        Offset(size.width * (x - 0.02), size.height * 0.35),
        reedPaint,
      );
    }
  }

  void _paintCottage(Canvas canvas, Size size) {
    _paintBuilding(
      canvas,
      size,
      wall: const Color(0xFFFFD59A),
      roof: const Color(0xFFC75D61),
      door: const Color(0xFF6C493B),
    );
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.66),
      size.width * 0.025,
      Paint()..color = const Color(0xFFFFD45E),
    );
  }

  void _paintVet(Canvas canvas, Size size) {
    final building = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.14,
        size.height * 0.24,
        size.width * 0.72,
        size.height * 0.61,
      ),
      Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(building, Paint()..color = const Color(0xFFF5FAFF));
    canvas.drawRRect(
      building,
      Paint()
        ..color = const Color(0xFF4B7188)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, size.width * 0.025),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.42,
        size.height * 0.59,
        size.width * 0.18,
        size.height * 0.26,
      ),
      Paint()..color = const Color(0xFF75C5DF),
    );
    final crossPaint = Paint()..color = const Color(0xFFEE5966);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.44,
        size.height * 0.30,
        size.width * 0.12,
        size.height * 0.25,
      ),
      crossPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.375,
        size.height * 0.36,
        size.width * 0.25,
        size.height * 0.12,
      ),
      crossPaint,
    );
  }

  void _paintBuilding(
    Canvas canvas,
    Size size, {
    required Color wall,
    required Color roof,
    required Color door,
  }) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.18,
          size.height * 0.38,
          size.width * 0.64,
          size.height * 0.47,
        ),
        Radius.circular(size.width * 0.025),
      ),
      Paint()..color = wall,
    );
    final roofPath = Path()
      ..moveTo(size.width * 0.10, size.height * 0.42)
      ..lineTo(size.width * 0.50, size.height * 0.10)
      ..lineTo(size.width * 0.90, size.height * 0.42)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = roof);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.43,
        size.height * 0.57,
        size.width * 0.18,
        size.height * 0.28,
      ),
      Paint()..color = door,
    );
    for (final x in [0.27, 0.67]) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * x,
          size.height * 0.50,
          size.width * 0.12,
          size.height * 0.13,
        ),
        Paint()..color = const Color(0xFF9EDCF1),
      );
    }
  }

  void _paintTree(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.43,
          size.height * 0.35,
          size.width * 0.15,
          size.height * 0.52,
        ),
        Radius.circular(size.width * 0.04),
      ),
      Paint()..color = const Color(0xFF8B5A3C),
    );
    final leafPaint = Paint()..color = const Color(0xFF55B96A);
    for (final center in [
      const Offset(0.33, 0.32),
      const Offset(0.52, 0.20),
      const Offset(0.69, 0.33),
      const Offset(0.49, 0.40),
    ]) {
      canvas.drawCircle(
        Offset(size.width * center.dx, size.height * center.dy),
        size.width * 0.20,
        leafPaint,
      );
    }
    final scratchPaint = Paint()
      ..color = const Color(0xFFF2D3A2)
      ..strokeWidth = math.max(1, size.width * 0.016);
    for (var index = 0; index < 4; index++) {
      final y = size.height * (0.52 + index * 0.06);
      canvas.drawLine(
        Offset(size.width * 0.44, y),
        Offset(size.width * 0.56, y - size.height * 0.04),
        scratchPaint,
      );
    }
  }

  void _paintPark(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.10,
          size.height * 0.38,
          size.width * 0.80,
          size.height * 0.47,
        ),
        Radius.circular(size.width * 0.09),
      ),
      Paint()..color = const Color(0xFF70C985),
    );
    final fence = Paint()
      ..color = const Color(0xFFF4E2AE)
      ..strokeWidth = math.max(1.5, size.width * 0.025);
    for (var index = 0; index < 6; index++) {
      final x = size.width * (0.16 + index * 0.135);
      canvas.drawLine(
        Offset(x, size.height * 0.40),
        Offset(x, size.height * 0.69),
        fence,
      );
    }
    canvas.drawLine(
      Offset(size.width * 0.13, size.height * 0.53),
      Offset(size.width * 0.87, size.height * 0.53),
      fence,
    );
    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.72),
      size.width * 0.10,
      Paint()..color = const Color(0xFFFFF7E5),
    );
    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.72),
      size.width * 0.04,
      Paint()..color = const Color(0xFF303A4E),
    );
  }

  void _paintGarden(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xFF4FA968)
      ..strokeWidth = math.max(1.5, size.width * 0.018);
    const colors = [
      Color(0xFFFF76B7),
      Color(0xFFFFD45E),
      Color(0xFF70B8FF),
      Color(0xFFB98AF4),
    ];
    for (var index = 0; index < 7; index++) {
      final x = size.width * (0.14 + index * 0.12);
      final top = size.height * (0.30 + (index.isEven ? 0.08 : 0));
      canvas.drawLine(
        Offset(x, size.height * 0.82),
        Offset(x, top),
        stemPaint,
      );
      canvas.drawCircle(
        Offset(x, top),
        size.width * 0.07,
        Paint()..color = colors[index % colors.length],
      );
      canvas.drawCircle(
        Offset(x, top),
        size.width * 0.025,
        Paint()..color = const Color(0xFFFFF2A8),
      );
    }
  }

  void _paintBed(Canvas canvas, Size size) {
    final frame = Paint()..color = const Color(0xFF8B5A4B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.11,
          size.height * 0.44,
          size.width * 0.78,
          size.height * 0.35,
        ),
        Radius.circular(size.width * 0.08),
      ),
      Paint()..color = const Color(0xFF8FA8FF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.17,
          size.height * 0.47,
          size.width * 0.28,
          size.height * 0.14,
        ),
        Radius.circular(size.width * 0.07),
      ),
      Paint()..color = const Color(0xFFFFF7E5),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.09,
        size.height * 0.38,
        size.width * 0.07,
        size.height * 0.49,
      ),
      frame,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.84,
        size.height * 0.62,
        size.width * 0.07,
        size.height * 0.25,
      ),
      frame,
    );
  }

  void _paintToys(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.20,
          size.height * 0.48,
          size.width * 0.60,
          size.height * 0.37,
        ),
        Radius.circular(size.width * 0.04),
      ),
      Paint()..color = const Color(0xFFD9894E),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.43,
        size.width * 0.68,
        size.height * 0.10,
      ),
      Paint()..color = const Color(0xFFA85E39),
    );
    final balls = <(Offset, Color)>[
      (const Offset(0.32, 0.43), const Color(0xFFFF6174)),
      (const Offset(0.50, 0.37), const Color(0xFF70B8FF)),
      (const Offset(0.68, 0.45), const Color(0xFFFFD45E)),
    ];
    for (final ball in balls) {
      canvas.drawCircle(
        Offset(size.width * ball.$1.dx, size.height * ball.$1.dy),
        size.width * 0.11,
        Paint()..color = ball.$2,
      );
    }
  }

  void _paintGameStation(Canvas canvas, Size size) {
    final cabinet = Path()
      ..moveTo(size.width * 0.25, size.height * 0.16)
      ..lineTo(size.width * 0.75, size.height * 0.16)
      ..lineTo(size.width * 0.82, size.height * 0.85)
      ..lineTo(size.width * 0.18, size.height * 0.85)
      ..close();
    canvas.drawPath(cabinet, Paint()..color = const Color(0xFF7659C9));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.31,
          size.height * 0.25,
          size.width * 0.38,
          size.height * 0.27,
        ),
        Radius.circular(size.width * 0.025),
      ),
      Paint()..color = const Color(0xFF92E7EA),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.59,
        size.width * 0.50,
        size.height * 0.09,
      ),
      Paint()..color = const Color(0xFF3B315F),
    );
    canvas.drawCircle(
      Offset(size.width * 0.42, size.height * 0.62),
      size.width * 0.04,
      Paint()..color = const Color(0xFFFF6174),
    );
    canvas.drawCircle(
      Offset(size.width * 0.61, size.height * 0.62),
      size.width * 0.035,
      Paint()..color = const Color(0xFFFFD45E),
    );
  }

  @override
  bool shouldRepaint(covariant _WorldPlacePainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.accent != accent ||
      oldDelegate.highlighted != highlighted;
}

class _PerspectiveYardPainter extends CustomPainter {
  const _PerspectiveYardPainter({
    required this.cameraX,
    required this.cameraHeight,
    required this.cameraZ,
    required this.cameraYaw,
    required this.darkMode,
  });

  final double cameraX;
  final double cameraHeight;
  final double cameraZ;
  final double cameraYaw;
  final bool darkMode;

  @override
  void paint(Canvas canvas, Size size) {
    final horizon = size.height * 0.27;
    final ground = Rect.fromLTRB(0, horizon, size.width, size.height);
    canvas.drawRect(
      ground,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: darkMode
              ? const [Color(0x22134B56), Color(0x77203545)]
              : const [Color(0x1847B69B), Color(0x66539865)],
        ).createShader(ground),
    );

    final gridPaint = Paint()
      ..color = (darkMode ? const Color(0x559FD8FF) : const Color(0x558FFFF0))
      ..strokeWidth = 1;
    for (var x = PetWorldSimulation.minX.toInt();
        x <= PetWorldSimulation.maxX;
        x += 4) {
      _drawWorldLine(
        canvas,
        size,
        gridPaint,
        x.toDouble(),
        0,
        PetWorldSimulation.minZ,
        x.toDouble(),
        0,
        PetWorldSimulation.maxZ,
      );
    }
    for (var z = PetWorldSimulation.minZ.toInt();
        z <= PetWorldSimulation.maxZ;
        z += 4) {
      _drawWorldLine(
        canvas,
        size,
        gridPaint,
        PetWorldSimulation.minX,
        0,
        z.toDouble(),
        PetWorldSimulation.maxX,
        0,
        z.toDouble(),
      );
    }

    final boundaryPaint = Paint()
      ..color = const Color(0xCCF7E6A1)
      ..strokeWidth = 3;
    _drawWorldLine(
      canvas,
      size,
      boundaryPaint,
      PetWorldSimulation.minX,
      0,
      PetWorldSimulation.minZ,
      PetWorldSimulation.maxX,
      0,
      PetWorldSimulation.minZ,
    );
    _drawWorldLine(
      canvas,
      size,
      boundaryPaint,
      PetWorldSimulation.maxX,
      0,
      PetWorldSimulation.minZ,
      PetWorldSimulation.maxX,
      0,
      PetWorldSimulation.maxZ,
    );
    _drawWorldLine(
      canvas,
      size,
      boundaryPaint,
      PetWorldSimulation.maxX,
      0,
      PetWorldSimulation.maxZ,
      PetWorldSimulation.minX,
      0,
      PetWorldSimulation.maxZ,
    );
    _drawWorldLine(
      canvas,
      size,
      boundaryPaint,
      PetWorldSimulation.minX,
      0,
      PetWorldSimulation.maxZ,
      PetWorldSimulation.minX,
      0,
      PetWorldSimulation.minZ,
    );

    final bowl = _project(
      size,
      PetWorldSimulation.foodX,
      0,
      PetWorldSimulation.foodZ,
    );
    if (bowl != null) {
      final pulse =
          18 + math.sin(DateTime.now().millisecondsSinceEpoch / 260) * 3;
      canvas.drawOval(
        Rect.fromCenter(
          center: bowl,
          width: pulse * 4,
          height: pulse * 1.3,
        ),
        Paint()
          ..color = const Color(0x99FFD45E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    _drawAxis(canvas, size, 0, 0, 0, 2.4, 0, 0, const Color(0xFFFF6174), 'X');
    _drawAxis(canvas, size, 0, 0, 0, 0, 2.4, 0, const Color(0xFF65E39D), 'Y');
    _drawAxis(canvas, size, 0, 0, 0, 0, 0, 2.4, const Color(0xFF5DAEFF), 'Z');
  }

  void _drawAxis(
    Canvas canvas,
    Size size,
    double x1,
    double y1,
    double z1,
    double x2,
    double y2,
    double z2,
    Color color,
    String label,
  ) {
    final a = _project(size, x1, y1, z1);
    final b = _project(size, x2, y2, z2);
    if (a == null || b == null) return;
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = 3,
    );
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, b + const Offset(3, -8));
  }

  void _drawWorldLine(
    Canvas canvas,
    Size size,
    Paint paint,
    double x1,
    double y1,
    double z1,
    double x2,
    double y2,
    double z2,
  ) {
    const segments = 32;
    final path = Path();
    var active = false;
    for (var index = 0; index <= segments; index++) {
      final amount = index / segments;
      final point = _project(
        size,
        x1 + (x2 - x1) * amount,
        y1 + (y2 - y1) * amount,
        z1 + (z2 - z1) * amount,
      );
      if (point == null) {
        active = false;
      } else if (!active) {
        path.moveTo(point.dx, point.dy);
        active = true;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  Offset? _project(
    Size size,
    double worldX,
    double worldY,
    double worldZ,
  ) {
    const cameraDistance = 5.4;
    final relativeX = worldX - cameraX;
    final relativeZ = worldZ - cameraZ;
    final cosine = math.cos(cameraYaw);
    final sine = math.sin(cameraYaw);
    final right = cosine * relativeX - sine * relativeZ;
    final forward = sine * relativeX + cosine * relativeZ;
    final depth = cameraDistance + forward;
    if (depth <= 0.55) return null;
    final focal = size.height * 1.06;
    return Offset(
      size.width / 2 + right * focal / depth,
      size.height * 0.27 + (cameraHeight - worldY) * focal / depth,
    );
  }

  @override
  bool shouldRepaint(covariant _PerspectiveYardPainter oldDelegate) =>
      oldDelegate.cameraX != cameraX ||
      oldDelegate.cameraHeight != cameraHeight ||
      oldDelegate.cameraZ != cameraZ ||
      oldDelegate.cameraYaw != cameraYaw ||
      oldDelegate.darkMode != darkMode;
}

Color _landmarkColor(PetWorldLandmarkKind kind) => switch (kind) {
      PetWorldLandmarkKind.pond => const Color(0xFF46BFE3),
      PetWorldLandmarkKind.cottage => const Color(0xFFFFA85A),
      PetWorldLandmarkKind.scratchingTree => const Color(0xFF69C56D),
      PetWorldLandmarkKind.playPark => const Color(0xFFFFD45E),
      PetWorldLandmarkKind.flowerGarden => const Color(0xFFF184C2),
      PetWorldLandmarkKind.vetClinic => const Color(0xFF62C9D2),
      PetWorldLandmarkKind.petBed => const Color(0xFF8FA8FF),
      PetWorldLandmarkKind.toyYard => const Color(0xFFFF8E7A),
      PetWorldLandmarkKind.gameStation => const Color(0xFF9B78E5),
    };

class _WorldMiniMapPainter extends CustomPainter {
  const _WorldMiniMapPainter({
    required this.playerX,
    required this.playerZ,
    required this.cameraYaw,
  });

  final double playerX;
  final double playerZ;
  final double cameraYaw;

  @override
  void paint(Canvas canvas, Size size) {
    final mapRect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(mapRect, const Radius.circular(7)),
      Paint()..color = const Color(0xAA315C50),
    );

    Offset mapPoint(double x, double z) => Offset(
          (x - PetWorldSimulation.minX) /
              (PetWorldSimulation.maxX - PetWorldSimulation.minX) *
              size.width,
          size.height -
              (z - PetWorldSimulation.minZ) /
                  (PetWorldSimulation.maxZ - PetWorldSimulation.minZ) *
                  size.height,
        );

    final bowl = mapPoint(
      PetWorldSimulation.foodX,
      PetWorldSimulation.foodZ,
    );
    canvas.drawCircle(
      bowl,
      4,
      Paint()..color = const Color(0xFFFFD45E),
    );
    canvas.drawCircle(
      bowl,
      6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    for (final landmark in PetWorldSimulation.landmarks) {
      final point = mapPoint(landmark.x, landmark.z);
      canvas.drawCircle(
          point, 3.5, Paint()..color = _landmarkColor(landmark.kind));
    }

    final player = mapPoint(playerX, playerZ);
    final heading = Offset(math.sin(cameraYaw), -math.cos(cameraYaw));
    canvas.drawLine(
      player,
      player + heading * 11,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(player, 4.5, Paint()..color = const Color(0xFFFF6174));
    canvas.drawCircle(
      player,
      6.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _WorldMiniMapPainter oldDelegate) =>
      oldDelegate.playerX != playerX ||
      oldDelegate.playerZ != playerZ ||
      oldDelegate.cameraYaw != cameraYaw;
}
