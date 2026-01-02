import 'dart:async';

import 'package:mpg_achievements_app/isometric/src/core/level/level_object.dart';
import 'package:mpg_achievements_app/isometric/src/core/level/tile.dart';
import 'package:mpg_achievements_app/isometric/src/core/level/tiled_layer.dart';
import 'package:xml/xml.dart';
import 'package:path/path.dart' as p;

//generic function for reading a file from path
typedef FileReader = Future<String> Function(String path);

class TiledLevel {
  List<TiledLayer> layers;
  List<LevelObjectLayer> objectLayers;
  Map<int, LevelTile> tilesetData;

  TiledLevel({required this.layers, required this.objectLayers, required this.tilesetData});

  static Future<TiledLevel> loadXML(XmlDocument document, {
    required String filename, required FileReader fileReader,
  }) async {
    final mapElement = document.getElement('map');
    final String baseDir = p.dirname(filename);
    print('baseDir');
    print(baseDir);

    /*potential switch to factory again if we load everything at the beginning, now Future becaus of tsx. files
  factory TiledLevel.fromXml(XmlDocument document){
    final mapElement = document.getElement('map');*/

    if (mapElement == null) {
      throw Exception('Invalid TMX file: Missing <map> element.');
    }

    /*final width = int.parse(mapElement.getAttribute('width') ?? '0');
    final height = int.parse(mapElement.getAttribute('height') ?? '0');*/

    //parse tilesetData
    final tilesetData = <int, LevelTile>{};

    for (final tileset in mapElement.findElements('tileset')) {
      final firstGid = int.parse(tileset.getAttribute('firstgid') ?? '1');
      final String? source = tileset.getAttribute('source');

      XmlElement? tilesetRoot;
      // Note: If your tileset is an external .tsx source load here
      if (source != null) {
        //make source directory
        final tsxPath = p.url.join(baseDir, source);
        print('tsxPath');
        print(tsxPath);
        //fetch content
        final tsxContent = await fileReader(tsxPath);
        tilesetRoot = XmlDocument.parse(tsxContent).getElement('tileset');
      }

      // Safety check
      if (tilesetRoot == null) continue;

      for (final tile in tilesetRoot.findElements('tile')) {
        final localId = int.parse(tile.getAttribute('id') ?? '0');
        final globalId = firstGid + localId;

        final properties = <String, dynamic>{};
        final propsElement = tile.getElement('properties');

        if (propsElement != null) {
          for (final prop in propsElement.findElements('property')) {
            final name = prop.getAttribute('name');
            final value = prop.getAttribute('value');
            if (name != null) {
              properties[name] = value;
            }
          }
        }

        // that contains "assets/models/name.glb"
        final String? modelPath = properties['model_path'];
        //give to tiled_level at the end
        tilesetData[globalId] = LevelTile(
          id: globalId,
          modelPath: modelPath,
          properties: properties,
        );
      }
    }

    //parse layers
    // layers are provided for level
    final layers = <TiledLayer>[];

    for (final layerElement in mapElement.findElements('layer')) {
      final layerName = layerElement.getAttribute('name') ?? 'Unnamed Layer';
      final tileInstances = <TileInstance>[];
      /*final layerWidth = int.parse(layerElement.getAttribute('width') ?? '0');
      final layerHeight = int.parse(layerElement.getAttribute('height') ?? '0'); -> only if finite map*/

      final dataElement = layerElement.getElement('data');
      if (dataElement == null) continue;
      //parse chunks
      final chunks = dataElement.findElements('chunk');
      //infinte map
      if (chunks.isNotEmpty) {
        for (final chunk in chunks) {
          final int chunkX = int.parse(chunk.getAttribute('x') ?? '0');
          final int chunkY = int.parse(chunk.getAttribute('y') ?? '0');
          //grab the text inside the XML tags as String trim removes spaces
          final String text = chunk.innerText.trim();
          //splits text into rows
          final List<String> rows = text.split('\n');

          int localRow = 0;
          for (final row in rows) {
            if (row
                .trim()
                .isEmpty) continue;
            final List<String> cols = row.split(',');
            int localCol = 0;
            for (final col in cols) {
              if (col
                  .trim()
                  .isEmpty) continue;

              final int gid = int.parse(col.trim());

              if (gid != 0) {
                //Combine Chunk Offset + local Position
                tileInstances.add(TileInstance(
                    chunkX + localCol,
                    chunkY + localRow,
                    gid));
              }
              localCol++;
            }
            localRow++;
          }
        }
      }
      //potential code for finite maps
      /*final encoding = dataElement.getAttribute('encoding');
      if (encoding != 'csv') {
        throw Exception(
          'Unsupported encoding: $encoding. Only CSV encoding is supported.',
        );
      }

      final csvData = dataElement.innerText.trim();
      final rows = csvData
          .split('\n')
          .map((row) => row.trim())
          .where((row) => row.isNotEmpty)
          .toList();

      if (rows.length != layerHeight) {
        throw Exception(
          'Layer height mismatch in layer $layerName: expected $layerHeight, found ${rows.length}.',
        );
      }

      final data = <List<int>>[];
      for (final row in rows) {
        final gids =
            (row.trim().split(
              ',',
            )..removeWhere((element) => element.isEmpty)).map((gid) {
              print("gid: '$gid'");
              return int.parse(gid.trim());
            }).toList();
        if (gids.length != layerWidth) {
          throw Exception(
            'Layer width mismatch in layer $layerName: expected $layerWidth, found ${gids.length}.',
          );
        }
        data.add(gids);
      }

      layers.add(
        TiledLayer(
          name: layerName,
          width: layerWidth,
          height: layerHeight,
          data: data,
        ),
      );
    }
    */
      //add the layer
      layers.add(TiledLayer(
          name: layerName,
          activeTiles: tileInstances,
      ));



    }
    //add null check
    final objectLayers = <LevelObjectLayer>[];
    for (final group in mapElement.findElements('object layer')) {
      final layerName = group.getAttribute('name') ?? 'Objects';
      final objects = <LevelObject>[];

      for (final obj in group.findElements('object')) {
        final properties = _parseProperties(obj);

        objects.add(LevelObject(
          id: int.parse(obj.getAttribute('id') ?? '0'),
          name: obj.getAttribute('name') ?? '',
          type: obj.getAttribute('class') ?? obj.getAttribute('type') ?? '',
          x: double.parse(obj.getAttribute('x') ?? '0'),
          y: double.parse(obj.getAttribute('y') ?? '0'),
          width: double.parse(obj.getAttribute('width') ?? '0'),
          height: double.parse(obj.getAttribute('height') ?? '0'),
          properties: properties,
        ));
      }
      objectLayers.add(LevelObjectLayer(name: layerName, objects: objects));
    }

    return TiledLevel(
      layers: layers,
      tilesetData: tilesetData,
      objectLayers: objectLayers,
    );

  }

  //extract properties from xml
  static Map<String, dynamic> _parseProperties(XmlElement element) {
    final properties = <String, dynamic>{};
    final propsElement = element.getElement('properties');
    if (propsElement != null) {
      for (final prop in propsElement.findElements('property')) {
        final name = prop.getAttribute('name');
        final value = prop.getAttribute('value');
        if (name != null) properties[name] = value;
      }
    }
    return properties;
  }

  LevelObjectLayer? getObjectLayer(String name) => objectLayers.firstWhere((l) => l.name == name);


}
