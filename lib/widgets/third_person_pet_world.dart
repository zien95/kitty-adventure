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
      _world = PetWorldSimulation(canFly: _isBird);
      _status = _isBird ? 'Take off and find the bowl' : 'Find the food bowl';
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
    if (events.contains(PetWorldEvent.ateFood)) {
      _status = '${widget.pet.name} landed on dinner!';
      widget.onEat();
    } else if (_world.nearFood) {
      _status = _isBird
          ? 'Fly low over the bowl to eat'
          : 'Jump onto the bowl to eat';
    } else if (_isBird && _world.y > 0.2) {
      _status = 'Flying at Y ${_world.y.toStringAsFixed(1)}';
    } else {
      _status = 'Bowl ${_world.distanceToFood.toStringAsFixed(1)}m away';
    }
    setState(() {});
  }

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
    if (_world.performAction()) {
      _status = _isBird ? 'Diving for dinner!' : 'Jumping for dinner!';
    } else {
      _status = 'Move closer to the food bowl';
    }
    _focusNode.requestFocus();
    setState(() {});
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
                        playerX: _world.x,
                        playerY: _world.y,
                        playerZ: _world.z,
                        cameraYaw: _world.cameraYaw,
                        darkMode:
                            Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                  ),
                  if (bowlProjection.visible)
                    _buildFoodBowl(bowlProjection, compact),
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
                    left: 10,
                    top: compact ? 72 : 58,
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
                _world.nearFood ? 'JUMP TO EAT' : 'BOWL',
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
        'WASD move • ← → camera • $flight • E action • drag to look',
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
          label: 'ACTION',
          icon: Icons.restaurant,
          color: const Color(0xFFEE7B66),
          onPressed: _doAction,
        ),
      ],
    );
  }

  _Projection _project(
    Size size,
    double worldX,
    double worldY,
    double worldZ,
  ) {
    const cameraDistance = 5.4;
    final cameraHeight = 2.75 + _world.y * 0.75;
    final relativeX = worldX - _world.x;
    final relativeZ = worldZ - _world.z;
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
        horizon + (cameraHeight - worldY) * focal / depth,
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

class _PerspectiveYardPainter extends CustomPainter {
  const _PerspectiveYardPainter({
    required this.playerX,
    required this.playerY,
    required this.playerZ,
    required this.cameraYaw,
    required this.darkMode,
  });

  final double playerX;
  final double playerY;
  final double playerZ;
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
        x += 2) {
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
        z += 2) {
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
    final cameraHeight = 2.75 + playerY * 0.75;
    final relativeX = worldX - playerX;
    final relativeZ = worldZ - playerZ;
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
      oldDelegate.playerX != playerX ||
      oldDelegate.playerY != playerY ||
      oldDelegate.playerZ != playerZ ||
      oldDelegate.cameraYaw != cameraYaw ||
      oldDelegate.darkMode != darkMode;
}
