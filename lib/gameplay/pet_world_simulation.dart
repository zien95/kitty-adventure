import 'dart:math' as math;

enum PetWorldEvent { ateFood }

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
  static const double minX = -8;
  static const double maxX = 8;
  static const double minZ = -4;
  static const double maxZ = 16;
  static const double maxFlightHeight = 6;

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

  bool jumpOrFlap() {
    if (canFly) {
      verticalVelocity = math.max(verticalVelocity, 3.1);
      return true;
    }
    if (y > 0.015) return false;
    verticalVelocity = 5.1;
    return true;
  }

  bool performAction() {
    if (!nearFood) return false;
    if (canFly) {
      verticalVelocity = y > 1.2 ? -3.8 : 2.7;
    } else {
      jumpOrFlap();
    }
    return true;
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
    final speed = canFly ? 4.8 : 3.7;

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
      if (y <= 0) {
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
