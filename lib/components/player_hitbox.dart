//hitbox is necessary for animations to look better so that collisions are better displayed

class PlayerHitbox {
  final double offsetX;
  final double offsetY;
  final double width;
  final double height;

  PlayerHitbox({
    required this.offsetX,
    required this.offsetY,
    required this.width,
    required this.height,
  });
}
