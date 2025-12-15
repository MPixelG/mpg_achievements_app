import 'package:mpg_achievements_app/isometric/src/core/level/tiled_layer.dart';
import 'package:xml/xml.dart';

class TiledLevel {
  int width;
  int height;

  List<TiledLayer> layers;

  TiledLevel({
    required this.width,
    required this.height,
    required this.layers,
  });

  factory TiledLevel.fromXml(XmlDocument document){
    final mapElement = document.getElement('map');
    if (mapElement == null) {
      throw Exception('Invalid TMX file: Missing <map> element.');
    }

    final width = int.parse(mapElement.getAttribute('width') ?? '0');
    final height = int.parse(mapElement.getAttribute('height') ?? '0');

    final layers = <TiledLayer>[];
    for (final layerElement in mapElement.findElements('layer')) {
      final layerName = layerElement.getAttribute('name') ?? 'Unnamed Layer';
      final layerWidth = int.parse(layerElement.getAttribute('width') ?? '0');
      final layerHeight = int.parse(layerElement.getAttribute('height') ?? '0');

      final dataElement = layerElement.getElement('data');
      if (dataElement == null) {
        throw Exception('Invalid TMX file: Missing <data> element in layer $layerName.');
      }

      final encoding = dataElement.getAttribute('encoding');
      if (encoding != 'csv') {
        throw Exception('Unsupported encoding: $encoding. Only CSV encoding is supported.');
      }

      final csvData = dataElement.text.trim();
      final rows = csvData.split('\n').map((row) => row.trim()).where((row) => row.isNotEmpty).toList();

      if (rows.length != layerHeight) {
        throw Exception('Layer height mismatch in layer $layerName: expected $layerHeight, found ${rows.length}.');
      }

      final data = <List<int>>[];
      for (final row in rows) {
        final gids = (row.trim().split(',')..removeWhere((element) => element.isEmpty)).map((gid) {
          print("gid: '$gid'");
          return int.parse(gid.trim());
        }).toList();
        if (gids.length != layerWidth) {
          throw Exception('Layer width mismatch in layer $layerName: expected $layerWidth, found ${gids.length}.');
        }
        data.add(gids);
      }

      layers.add(TiledLayer(
        name: layerName,
        width: layerWidth,
        height: layerHeight,
        data: data,
      ));
    }

    return TiledLevel(
      width: width,
      height: height,
      layers: layers,
    );
  }
}