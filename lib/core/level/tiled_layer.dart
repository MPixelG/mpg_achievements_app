class TiledLayer {
  final String name;
  final int width;
  final int height;
  final List<List<int>> data; // 2D array of tile GIDs

  TiledLayer({
    required this.name,
    required this.width,
    required this.height,
    required this.data,
  });
}