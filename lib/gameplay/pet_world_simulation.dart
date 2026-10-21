import 'dart:math' as math;

enum PetWorldEvent { ateFood }

enum PetWorldLandmarkKind {
  pond,
  cottage,
  scratchingTree,
  playPark,
  flowerGarden,
  vetClinic,
  petBed,
  toyYard,
  gameStation,
}

class PetWorldLandmark {
  const PetWorldLandmark({
    required this.kind,
    required this.label,
    required this.symbol,
    required this.actionLabel,
    required this.arrivalMessage,
    required this.x,
    required this.z,
    this.interactionRadius = 2.4,
  });

  final PetWorldLandmarkKind kind;
  final String label;
  final String symbol;
  final String actionLabel;
  final String arrivalMessage;
  final double x;
  final double z;
  final double interactionRadius;
}

class PetWorldActionResult {
  const PetWorldActionResult.foodBowl() : landmark = null;
  const PetWorldActionResult.landmark(this.landmark);

  final PetWorldLandmark? landmark;

  bool get isFoodBowl => landmark == null;
}

/// Platform-neutral movement and interaction rules for the third-person yard.
///
/// X runs left/right, Y is height, and Z runs forward/back. Rendering and input
/// live in the widget layer so this simulation can be tested without a device.
class PetWorldSimulation {
  PetWorldSimulation({
    required this.canFly,
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.cameraYaw = 0,
  });

  static const double foodX = 2.4;
  static const double foodZ = 3.6;
  static const double foodBowlHeight = 0.34;
  static const double foodSurfaceRadius = 0.78;
  static const double minX = -36;
  static const double maxX = 36;
  static const double minZ = -18;
  static const double maxZ = 72;
  static const double maxFlightHeight = 12;

  static const List<PetWorldLandmark> landmarks = [
    PetWorldLandmark(
      kind: PetWorldLandmarkKind.pond,
      label: 'Duck Pond',
      symbol: '🦆',
      actionLabel: 'SPLASH',
      arrivalMessage: 'Splashed and freshened up at Duck Pond!',
      x: -15,
      z: 12,
    ),
    PetWorldLandmark(
      kind: PetWorldLandmarkKind.cottage,
      label: 'Pet Cottage',
      symbol: '🏡',
      actionLabel: 'ENTER',
      arrivalMessage: 'Entered the cottage for some cozy bonding time!',
      x: -20,
      z: 30,
    ),
    PetWorldLandmark(
      kind: PetWorldLandmarkKind.scratchingTree,
      label: 'Climbing Tree',
      symbol: '🌳',
      actionLabel: 'CLIMB',
      arrivalMessage: 'Climbed the tree and practiced a new trick!',
      x: -26,
      z: 46,
    ),
    PetWorldLandmark(
      kind: PetWorldLandmarkKind.playPark,
      label: 'Play Park',
      symbol: '⚽',
      actionLabel: 'PLAY',
      arrivalMessage: 'Zoomies activated at the Play Park!',
      x: 20,
      z: 54,
    ),
    PetWorldLandmark(
      kind: PetWorldLandmarkKind.flowerGarden,
      label: 'Flower Garden',
      symbol: '🌸',
      actionLabel: 'EXPLORE',
      arrivalMessage: 'Explored the flowers and made a happy memory!',
      x: -7,
      z: 65,
    ),
    PetWorldLandmark(
      kind: PetWorldLandmarkKind.vetClinic,
      label: 'Happy Paws Vet',
      symbol: '🏥',
      actionLabel: 'ENTER',
      arrivalMessage: 'The vet completed a healthy-pet check-up!',
      x: 18,
      z: 24,
    ),
    PetWorldLandmark(
      kind: PetWorldLandmarkKind.petBed,
      label: 'Dreamy Bed',
      symbol: '🛏️',
      actionLabel: 'REST',
      arrivalMessage: 'Curled up for a restoring nap!',
      x: 10,
      z: 11,
    ),
    PetWorldLandmark(
      kind: PetWorldLandmarkKind.toyYard,
      label: 'Toy Yard',
      symbol: '🪀',
      actionLabel: 'PLAY',
      arrivalMessage: 'Picked a toy and started playtime!',
      x: -9,
      z: 19,
    ),
    PetWorldLandmark(
      kind: PetWorldLandmarkKind.gameStation,
      label: 'Game Station',
      symbol: '🎮',
      actionLabel: 'ENTER',
      arrivalMessage: 'Opened the Game Station!',
      x: 8,
      z: 38,
    ),
  ];

  final bool canFly;

  double x;
  double y;
  double z;
  double cameraYaw;
  double facingYaw = 0;
  double verticalVelocity = 0;

  bool _foodContactLatched = false;

  double get distanceToFood =>
      math.sqrt(math.pow(x - foodX, 2) + math.pow(z - foodZ, 2));

  bool get nearFood => distanceToFood <= 1.45;

  bool get onFoodBowl =>
      distanceToFood <= foodSurfaceRadius && (y - foodBowlHeight).abs() <= 0.08;

  PetWorldLandmark get nearestLandmark => landmarks.reduce(
        (nearest, landmark) =>
            distanceToLandmark(landmark) < distanceToLandmark(nearest)
                ? landmark
                : nearest,
      );

  PetWorldLandmark? get actionableLandmark {
    final landmark = nearestLandmark;
    return distanceToLandmark(landmark) <= landmark.interactionRadius
        ? landmark
        : null;
  }

  double distanceToLandmark(PetWorldLandmark landmark) => math.sqrt(
        math.pow(x - landmark.x, 2) + math.pow(z - landmark.z, 2),
      );

  bool jumpOrFlap() {
    if (canFly) {
      verticalVelocity = math.max(verticalVelocity, 3.1);
      return true;
    }
    final supportHeight = onFoodBowl ? foodBowlHeight : 0.0;
    if (y > supportHeight + 0.015) return false;
    verticalVelocity = 5.1;
    return true;
  }

  PetWorldActionResult? performAction() {
    if (nearFood) {
      if (canFly) {
        verticalVelocity = y > 1.2 ? -3.8 : 2.7;
      } else {
        jumpOrFlap();
      }
      return const PetWorldActionResult.foodBowl();
    }
    final landmark = actionableLandmark;
    return landmark == null ? null : PetWorldActionResult.landmark(landmark);
  }

  Set<PetWorldEvent> step({
    required double dt,
    double forward = 0,
    double right = 0,
    double turn = 0,
    bool ascend = false,
    bool descend = false,
  }) {
    final elapsed = dt.clamp(0.0, 0.05);
    cameraYaw = _wrapAngle(cameraYaw + turn * 1.75 * elapsed);

    var moveForward = forward.clamp(-1.0, 1.0);
    var moveRight = right.clamp(-1.0, 1.0);
    final magnitude = math.sqrt(
      moveForward * moveForward + moveRight * moveRight,
    );
    if (magnitude > 1) {
      moveForward /= magnitude;
      moveRight /= magnitude;
    }

    final forwardX = math.sin(cameraYaw);
    final forwardZ = math.cos(cameraYaw);
    final rightX = math.cos(cameraYaw);
    final rightZ = -math.sin(cameraYaw);
    final velocityX = moveForward * forwardX + moveRight * rightX;
    final velocityZ = moveForward * forwardZ + moveRight * rightZ;
    final wasStandingOnBowl = onFoodBowl && verticalVelocity <= 0;
    final speed = canFly ? 8.5 : 7.0;

    x = (x + velocityX * speed * elapsed).clamp(minX, maxX);
    z = (z + velocityZ * speed * elapsed).clamp(minZ, maxZ);
    if (velocityX.abs() + velocityZ.abs() > 0.01) {
      facingYaw = math.atan2(velocityX, velocityZ);
    }

    if (canFly) {
      if (ascend) verticalVelocity += 8.5 * elapsed;
      if (descend) verticalVelocity -= 8.5 * elapsed;
      if (!ascend && !descend) {
        verticalVelocity *= math.pow(0.12, elapsed).toDouble();
      }
      verticalVelocity = verticalVelocity.clamp(-4.2, 4.2);
      y = (y + verticalVelocity * elapsed).clamp(0, maxFlightHeight);
      if ((y == 0 && verticalVelocity < 0) ||
          (y == maxFlightHeight && verticalVelocity > 0)) {
        verticalVelocity = 0;
      }
    } else {
      verticalVelocity -= 10.2 * elapsed;
      y += verticalVelocity * elapsed;
      final overBowl = distanceToFood <= foodSurfaceRadius;
      if (overBowl && y <= foodBowlHeight && verticalVelocity <= 0) {
        // Ground pets step onto the low bowl as they walk into it. Jumping and
        // landing on it still works, but eating no longer needs a perfect jump.
        y = foodBowlHeight;
        verticalVelocity = 0;
      } else if (!overBowl && wasStandingOnBowl && verticalVelocity <= 0) {
        y = 0;
        verticalVelocity = 0;
      } else if (y <= 0) {
        y = 0;
        verticalVelocity = 0;
      }
    }

    final events = <PetWorldEvent>{};
    final touchingFood = distanceToFood <= 0.92 && y >= 0.24 && y <= 1.75;
    if (touchingFood && !_foodContactLatched) {
      _foodContactLatched = true;
      events.add(PetWorldEvent.ateFood);
    } else if (distanceToFood > 1.45 || y > 2.2) {
      _foodContactLatched = false;
    }
    return events;
  }

  double _wrapAngle(double angle) {
    while (angle > math.pi) {
      angle -= math.pi * 2;
    }
    while (angle < -math.pi) {
      angle += math.pi * 2;
    }
    return angle;
  }
}
