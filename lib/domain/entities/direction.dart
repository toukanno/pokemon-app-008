/// 4方向
enum Direction { up, down, left, right }

extension DirectionX on Direction {
  int get dx => this == Direction.left ? -1 : (this == Direction.right ? 1 : 0);
  int get dy => this == Direction.up ? -1 : (this == Direction.down ? 1 : 0);

  String get storageName => name;

  static Direction fromName(String? n) {
    switch (n) {
      case 'up':
        return Direction.up;
      case 'left':
        return Direction.left;
      case 'right':
        return Direction.right;
      default:
        return Direction.down;
    }
  }
}
