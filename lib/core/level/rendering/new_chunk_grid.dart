import 'dart:async';
import 'dart:core';
import 'dart:math';
import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:mpg_achievements_app/core/level/generation/chunk_generator.dart';
import 'package:mpg_achievements_app/core/level/rendering/cached_image_world_map.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:mpg_achievements_app/util/isometric_utils.dart';

import '../isometric/isometric_renderable.dart';
import 'chunk.dart';

class ChunkGrid {
  Map<Vector2, Chunk> chunks = {};

  bool _isRebuildingTerrain = false;
  bool _isRebuildingEntities = false;

  CachedImageWorldMap? _currentAlbedoCache;
  CachedImageWorldMap? _nextAlbedoCache;
  CachedImageWorldMap? _currentNormalCache;
  CachedImageWorldMap? _nextNormalCache;

  CachedImageWorldMap? _currentAlbedoCacheEntity;
  CachedImageWorldMap? _nextAlbedoCacheEntity;
  CachedImageWorldMap? _currentNormalCacheEntity;
  CachedImageWorldMap? _nextNormalCacheEntity;

  List<int> _lastEntityHashes = [];

  ChunkGenerator generator;

  ChunkGrid({required this.generator}){
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      tickNextFrame = true;
    });
    if (!shaderInitialized && !shaderBeingInitialized) {
      shaderBeingInitialized = true;
      initShader();
    }
  }

  void generateChunksInViewport(Vector2 position, Vector2 size) {
    final Set<Vector2> visibleChunkCoords = chunksVisibleByCamera(position, size);

    for (var coord in visibleChunkCoords) {
      if (!chunks.containsKey(coord)) {
        final Chunk newChunk = generator.generateChunk(coord.x.toInt(), coord.y.toInt());
        chunks[coord] = newChunk;
      }
    }
  }

  static const double viewportExtendPixels = 128;
  static const double upscaleFactor = 1;


  bool camOutsideCache(Vector2 camPos, CachedImageWorldMap? cache, Vector2 viewportSize) {
    if(cache == null) return true;

    final Vector2 cacheBR = cache.capturedSize + cache.pos;
    final Vector2 cacheTL = cache.pos;

    if(camPos.x < cacheTL.x || camPos.y < cacheTL.y) return true;
    if(camPos.x + viewportSize.x > cacheBR.x || camPos.y + viewportSize.y > cacheBR.y) return true;

    return false;
  }

  bool tickNextFrame = true;
  void tick(Vector2 position, Vector2 viewportSize, List<IsometricRenderable> components) {
    tickNextFrame = false;

    if (camOutsideCache(position, _currentAlbedoCache, viewportSize) ||
        _currentAlbedoCache == null) {
      if (!_isRebuildingTerrain) {
        _rebuildTerrainCachesAsync(
            position - Vector2.all(viewportExtendPixels/2),
            viewportSize + Vector2.all(viewportExtendPixels)
        );
      }
    }

    if (_shouldRebuildEntityCache(position, viewportSize, components)) {
      if (!_isRebuildingEntities) {
        _rebuildEntityCachesAsync(position, viewportSize, components);
      }
    }
  }

  bool _shouldRebuildEntityCache(
      Vector2 position,
      Vector2 viewportSize,
      List<IsometricRenderable> components
      ) {

    final currentHashes = components
        .map((c) => c.hashCode)
        .toList();

    if (currentHashes.length != _lastEntityHashes.length) {
      return true;
    }

    for (int i = 0; i < currentHashes.length; i++) {
      if (currentHashes[i] != _lastEntityHashes[i]) {
        return true;
      }
    }

    return components.any((c) => c.dirty);
  }

  double timeSinceLastRebuild = 0;
  Paint debugPaint = Paint()
    ..color = const Color(0x8813C52A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  Paint debugPaint2 = Paint()
    ..color = const Color(0x88FF0000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  Vector2 lastCamPos = Vector2.zero();
  Vector2 lastViewportSize = Vector2.zero();


  Paint shaderPaint = Paint();
  bool shaderInitialized = false;
  bool shaderBeingInitialized = false;

  Future<void> _rebuildEntityCachesAsync(
      Vector2 position,
      Vector2 viewportSize,
      List<IsometricRenderable> components
      ) async {
    if (_isRebuildingEntities) return;
    _isRebuildingEntities = true;

    _lastEntityHashes = components.map((c) => c.hashCode).toList();

    final PictureRecorder albedoRecorder = PictureRecorder();
    final PictureRecorder normalRecorder = PictureRecorder();

    final Canvas albedoCanvas = Canvas(albedoRecorder);
    final Canvas normalCanvas = Canvas(normalRecorder);

    albedoCanvas.translate(-position.x, -position.y);
    normalCanvas.translate(-position.x, -position.y);

    for (var component in components) {
      component.renderTree(
        albedoCanvas,
        normalCanvas,
            () => calculateNormalPaint(component, overridePaint),
      );
      component.setDirty(false);
    }

    try {
      final results = await Future.wait([
        albedoRecorder
            .endRecording()
            .toImage((viewportSize.x).toInt(), (viewportSize.y).toInt()),
        normalRecorder
            .endRecording()
            .toImage(viewportSize.x.toInt(), viewportSize.y.toInt()),
      ]);

      _nextAlbedoCacheEntity = CachedImageWorldMap(camPos: position, image: results[0]);
      _nextNormalCacheEntity = CachedImageWorldMap(camPos: position, image: results[1]);

      _currentAlbedoCacheEntity?.dispose();
      _currentNormalCacheEntity?.dispose();

      _currentAlbedoCacheEntity = _nextAlbedoCacheEntity;
      _currentNormalCacheEntity = _nextNormalCacheEntity;

    } catch (e) {
      print("Error rebuilding entity caches: $e");
    } finally {
      _isRebuildingEntities = false;
    }
  }

  Future<void> _rebuildTerrainCachesAsync(
      Vector2 position,
      Vector2 viewportSize
      ) async {
    if (_isRebuildingTerrain) return;
    _isRebuildingTerrain = true;

    final Set<Vector2> visibleChunkCoords = chunksVisibleByCamera(position, viewportSize);

    for (var coord in visibleChunkCoords) {
      if (!chunks.containsKey(coord)) {
        final Chunk newChunk = generator.generateChunk(coord.x.toInt(), coord.y.toInt());
        chunks[coord] = newChunk;
      }
    }

    final PictureRecorder albedoRecorder = PictureRecorder();
    final PictureRecorder normalRecorder = PictureRecorder();

    final Canvas albedoCanvas = Canvas(albedoRecorder);
    final Canvas normalCanvas = Canvas(normalRecorder);

    final Vector2 posTL = -position;
    albedoCanvas.translate(posTL.x, posTL.y);
    normalCanvas.translate(posTL.x, posTL.y);

    for (var chunk in chunks.values) {
      final Vector2 chunkPos = Vector2(
        ((chunk.x - chunk.z) * (Chunk.chunkSize)) * tilesize.x / 2,
        (chunk.x + chunk.z) * (Chunk.chunkSize) * tilesize.z / 2,
      );
      chunkPos.y -= chunk.yHeightUsedPixels;

      final Vector2 drawPos = chunk.albedoWorldTopLeft ?? chunkPos;

      albedoCanvas.save();
      normalCanvas.save();

      albedoCanvas.translate(drawPos.x, drawPos.y);
      normalCanvas.translate(drawPos.x, drawPos.y);

      chunk.render(albedoCanvas, normalCanvas);

      albedoCanvas.restore();
      normalCanvas.restore();
    }

    try {
      final results = await Future.wait([
        albedoRecorder
            .endRecording()
            .toImage((viewportSize.x).toInt(), (viewportSize.y).toInt()),
        normalRecorder
            .endRecording()
            .toImage(viewportSize.x.toInt(), viewportSize.y.toInt()),
      ]);

      _nextAlbedoCache = CachedImageWorldMap(camPos: position, image: results[0]);
      _nextNormalCache = CachedImageWorldMap(camPos: position, image: results[1]);

      _currentAlbedoCache?.dispose();
      _currentNormalCache?.dispose();

      _currentAlbedoCache = _nextAlbedoCache;
      _currentNormalCache = _nextNormalCache;

    } catch (e) {
      print("Error rebuilding terrain caches: $e");
    } finally {
      _isRebuildingTerrain = false;
    }
  }

  void render(
      Canvas canvas,
      List<IsometricRenderable> components,
      Vector2 position,
      Vector2 viewportSize,
      ) {
    tick(position, viewportSize, components);

    if (_currentNormalCache != null &&
        _currentAlbedoCache != null &&
        shader != null) {

      canvas.save();
      shader!.setImageSampler(0, _currentAlbedoCache!.image);
      shader!.setImageSampler(1, _currentNormalCache!.image);
      shader!.setImageSampler(2, _currentAlbedoCacheEntity!.image);
      shader!.setImageSampler(3, _currentNormalCacheEntity!.image);

      final double time = DateTime.now().millisecondsSinceEpoch / 10000;
      final double lightX = cos(time) * 300;
      final double lightZ = sin(time) * 300;

      shader!.setFloatUniforms((val) {
        val.setFloats([
          _currentAlbedoCache!.width,
          _currentAlbedoCache!.height,
          _currentAlbedoCacheEntity!.width,
          _currentAlbedoCacheEntity!.height,
          _currentAlbedoCache!.pos.x - _currentAlbedoCacheEntity!.pos.x,
          _currentAlbedoCache!.pos.y - _currentAlbedoCacheEntity!.pos.y,
          lightX,
          lightZ,
          35
        ]);
      });

      shaderPaint.shader = shader;
      canvas.translate(_currentAlbedoCache!.pos.x, _currentAlbedoCache!.pos.y);
      canvas.drawRect((viewportSize + Vector2.all(viewportExtendPixels)).toRect(), shaderPaint);

      canvas.restore();
    }

    if (_currentNormalCacheEntity != null &&
        _currentAlbedoCacheEntity != null) {
      canvas.save();
      // canvas.drawImage(
      //     _currentAlbedoCacheEntity!.image,
      //     (_currentAlbedoCacheEntity!.pos).toOffset(), //a bit of transparency to indicate loading
      //     Paint()..colorFilter = const ColorFilter.mode(
      //       Color(0x25FFFFFF),
      //       BlendMode.modulate,
      //     )
      // );
      canvas.restore();
    }
  }


  Paint overridePaint = Paint()..isAntiAlias = false..filterQuality = FilterQuality.none;



  bool rebuild = true;

  FragmentShader? shader;
  void initShader() async {
    final FragmentProgram program = await FragmentProgram.fromAsset(
      "assets/shaders/lighting.frag",
    );
    shader = program.fragmentShader();
  }


  Set<Vector2> chunksVisibleByCamera(Vector2 position, Vector2 size) {
    final Vector2 topLeft = position;
    final Vector2 bottomRight = position + size;
    return chunksInScreenRect(topLeft, bottomRight);
  }

  Set<Vector2> chunksInScreenRect(Vector2 topLeft, Vector2 bottomRight) {
    final Vector2 topLeftWorld = toWorldPos2D(topLeft)..floor();
    final Vector2 bottomRightWorld = toWorldPos2D(bottomRight)..floor();
    return chunksInWorldRect(topLeftWorld, bottomRightWorld);
  }

  Set<Vector2> chunksInWorldRect(Vector2 topLeft, Vector2 bottomRight) {
    final Vector2 topLeftChunk = chunkAtWorldPos(topLeft);
    final Vector2 bottomRightChunk = chunkAtWorldPos(bottomRight);

    final Set<Vector2> chunkCoords = {};

    for (int x = topLeftChunk.x.toInt(); x <= bottomRightChunk.x.toInt(); x++) {
      for (int z = topLeftChunk.y.toInt(); z <= bottomRightChunk.y.toInt(); z++) {
        chunkCoords.add(Vector2(x.toDouble(), z.toDouble()));
      }
    }

    return chunkCoords;
  }

  Vector2 chunkAtWorldPos(Vector2 worldPos) {
    final int chunkX = (worldPos.x / (Chunk.chunkSize * tilesize.x)).floor();
    final int chunkZ = (worldPos.y / (Chunk.chunkSize * tilesize.y)).floor();
    return Vector2(chunkX.toDouble(), chunkZ.toDouble());
  }
}


Paint calculateNormalPaint(IsometricRenderable renderable, Paint overridePaint) {
  final double footY = renderable.gridFeetPos.y;
  final double headY = footY + renderable.size.y;

  final double footValue = (footY / Chunk.highestYTileInWorld);
  final double headValue = (headY / Chunk.highestYTileInWorld);

  final double scale = (headValue - footValue);
  final double offset = footValue * 255;

  overridePaint.colorFilter = ColorFilter.matrix([
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, scale, 0, offset,
    0, 0, 0, 1, 0,
  ]);

  return overridePaint;
}