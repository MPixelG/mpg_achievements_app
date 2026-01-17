class LevelObject {
  final int id;
  final String name;
  final String type; // Tiled 'class'
  final double x;
  final double y;
  final double width;
  final double height;
  final Map<String, dynamic> properties;

  LevelObject({
    required this.id,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.properties,
  });
}

class LevelObjectLayer {
  final String name;
  final List<LevelObject> objects;

  LevelObjectLayer({required this.name, required this.objects});

}