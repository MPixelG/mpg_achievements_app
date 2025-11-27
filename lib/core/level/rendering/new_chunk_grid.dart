import 'dart:core';
import 'dart:math';
import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/core/level/generation/chunk_generator.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:mpg_achievements_app/util/isometric_utils.dart';

import '../isometric/isometric_renderable.dart';
import 'cached_image_world_map.dart';
import 'chunk.dart';

class ChunkGrid {
  Map<Vector2, Chunk> chunks = {};

  bool _isRebuildingTerrain = false;
  bool _isRebuildingEntities = false;

  CachedImageWorldMap? _currentAlbedoCache;
  CachedImageWorldMap? _nextAlbedoCache;
  CachedImageWorldMap? _currentDepthCache;
  CachedImageWorldMap? _nextDepthCache;

  CachedImageWorldMap? _currentAlbedoCacheEntity;
  CachedImageWorldMap? _nextAlbedoCacheEntity;
  CachedImageWorldMap? _currentDepthCacheEntity;
  CachedImageWorldMap? _nextDepthCacheEntity;

  List<int> _lastEntityHashes = [];

  ChunkGenerator generator;

  ChunkGrid({required this.generator}){
    if (!shaderInitialized && !shaderBeingInitialized) {
      shaderBeingInitialized = true;
      initShader();
    }
  }

  static const double viewportExtendPixels = 128;
  static const double camRegeneratePadding = 32;

  bool camOutsideCache(Vector2 camPos, CachedImageWorldMap? cache, Vector2 virtualViewportSize, double zoom) {
    if(cache == null || rebuild) return true;

    final Vector2 cacheTL = cache.pos;
    final Vector2 cacheBR = cache.capturedSize + cache.pos;

    final Vector2 camTL = camPos - Vector2.all(camRegeneratePadding/2);
    final Vector2 camBR = camPos + virtualViewportSize + Vector2.all(camRegeneratePadding/2);
    
    if(camTL.x < cacheTL.x || camTL.y < cacheTL.y) return true;
    if(camBR.x > cacheBR.x || camBR.y > cacheBR.y) return true;

    return false;
  }

  void tick(Vector2 position, Vector2 virtualViewportSize, Vector2 imageSize, List<IsometricRenderable> components, double zoom) {
    components.sort((a, b) => depth(a).compareTo(depth(b)));

    if (camOutsideCache(position, _currentAlbedoCache, imageSize, zoom) ||
        _currentAlbedoCache == null) {
      if (!_isRebuildingTerrain) {
        _rebuildTerrainCaches(
            position - Vector2.all(viewportExtendPixels/2),
            virtualViewportSize,
            imageSize + Vector2.all(viewportExtendPixels),
            zoom,
        );
      }
    }

    if (_shouldRebuildEntityCache(position, virtualViewportSize, components)) {
      _rebuildEntityCachesAsync(
          position - Vector2.all(viewportExtendPixels/2),
          virtualViewportSize,
          imageSize + Vector2.all(viewportExtendPixels),
          zoom,
          components
      );
    }
    rebuild = false;
  }

  bool _shouldRebuildEntityCache(
      Vector2 position,
      Vector2 virtualViewportSize,
      List<IsometricRenderable> components
      ) {
    if (_isRebuildingEntities) return false;
    if (rebuild) return true;

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
  
  Vector2 lastCamPos = Vector2.zero();
  Vector2 lastViewportSize = Vector2.zero();


  Paint shaderPaint = Paint();
  bool shaderInitialized = false;
  bool shaderBeingInitialized = false;
  
  Future<List<CachedImageWorldMap>?> renderToImage(Vector2 position, Vector2 virtualViewportSize, Vector2 imageSize, double zoom, void Function(Canvas albedoCanvas, Canvas depthCanvas) render) async{
    final PictureRecorder albedoRecorder = PictureRecorder();
    final PictureRecorder depthRecorder = PictureRecorder();

    final Canvas albedoCanvas = Canvas(albedoRecorder);
    final Canvas depthCanvas = Canvas(depthRecorder);
    
    
    final Vector2 centerOffset = imageSize / 2;
    final Vector2 worldCenter = position + imageSize/2;

    albedoCanvas.translate(centerOffset.x, centerOffset.y);
    depthCanvas.translate(centerOffset.x, centerOffset.y);

    albedoCanvas.scale(1 / zoom);
    depthCanvas.scale(1 / zoom);

    albedoCanvas.translate(-worldCenter.x, -worldCenter.y);
    depthCanvas.translate(-worldCenter.x, -worldCenter.y);
    
    render(albedoCanvas, depthCanvas);

    try {
      final results = await Future.wait([
        albedoRecorder
            .endRecording()
            .toImage((imageSize.x).toInt(), (imageSize.y).toInt()),
        depthRecorder
            .endRecording()
            .toImage(imageSize.x.toInt(), imageSize.y.toInt()),
      ]);

      final CachedImageWorldMap result1 = CachedImageWorldMap(camPos: position / zoom, image: results[0], capturedSize: imageSize, zoom: zoom);
      final CachedImageWorldMap result2 = CachedImageWorldMap(camPos: position / zoom, image: results[1], capturedSize: imageSize, zoom: zoom);
      
      return [result1, result2];

    } catch (e) {
      print("Error rebuilding caches: $e");
    }
    return null;
  }

  Future<void> _rebuildEntityCachesAsync(
      Vector2 position,
      Vector2 virtualViewportSize,
      Vector2 imageSize,
      double zoom,
      List<IsometricRenderable> components,
      ) async {
    if (_isRebuildingEntities) return;
    _isRebuildingEntities = true;
    _lastEntityHashes = components.map((c) => c.hashCode).toList();

    renderToImage(position, virtualViewportSize, imageSize, zoom, (albedoCanvas, depthCanvas) {
      for (var component in components) {
        component.renderTree(
          albedoCanvas,
          depthCanvas,
              () => calculateDepthPaint(component, overridePaint),
        );
        component.setDirty(false);
      }
    }).then((results) {
      _nextAlbedoCacheEntity = results?[0];
      _nextDepthCacheEntity = results?[1];

      _currentAlbedoCacheEntity?.dispose();
      _currentDepthCacheEntity?.dispose();

      _currentAlbedoCacheEntity = _nextAlbedoCacheEntity;
      _currentDepthCacheEntity = _nextDepthCacheEntity;
      _isRebuildingEntities = false;
    });
  }
  
  Future<void> generateVisibleChunks(Vector2 position, Vector2 viewportSize) async{
    final Set<Vector2> visibleChunkCoords = chunksVisibleByCamera(position, viewportSize);

    for (var coord in visibleChunkCoords) {
      if (!chunks.containsKey(coord)) {
        generator.generateChunk(coord.x.toInt(), coord.y.toInt()).then((value) => chunks[coord] = value);
      }
    }
  }
  
  Future<void> _rebuildTerrainCaches(
      Vector2 position,
      Vector2 virtualViewportSize,
      Vector2 imageSize,
      double zoom,
      ) async {
    if (_isRebuildingTerrain) return;
    _isRebuildingTerrain = true;
    generateVisibleChunks(position, virtualViewportSize);
    
    renderToImage(position, virtualViewportSize, imageSize, zoom, (albedoCanvas, depthCanvas) {
      for (var chunk in chunks.values) {
        final Vector2 chunkPos = Vector2(
          ((chunk.x - chunk.z) * (Chunk.chunkSize)) * tilesize.x / 2,
          (chunk.x + chunk.z) * (Chunk.chunkSize) * tilesize.z / 2,
        );
        chunkPos.y -= chunk.yHeightUsedPixels;

        final Vector2 drawPos = chunk.albedoWorldTopLeft ?? chunkPos;

        albedoCanvas.save();
        depthCanvas.save();

        albedoCanvas.translate(drawPos.x, drawPos.y);
        depthCanvas.translate(drawPos.x, drawPos.y);

        chunk.render(albedoCanvas, depthCanvas);

        albedoCanvas.restore();
        depthCanvas.restore();
      }
    }).then((results) {
      _nextAlbedoCache = results?[0];
      _nextDepthCache = results?[1];

      _currentAlbedoCache?.dispose();
      _currentDepthCache?.dispose();

      _currentAlbedoCache = _nextAlbedoCache;
      _currentDepthCache = _nextDepthCache;
      _isRebuildingTerrain = false;
    });
  }

  bool debugRender = false;
  void render(
      Canvas canvas,
      List<IsometricRenderable> components,
      Vector2 position,
      Vector2 virtualViewportSize,
      Vector2 imageSize,
      double zoom
      ) {
    tick(position, virtualViewportSize, imageSize, components, zoom);

    if (_currentDepthCache != null &&
        _currentAlbedoCache != null &&
        _currentAlbedoCacheEntity != null &&
        _currentDepthCacheEntity != null &&
        shader != null) {

      canvas.save();
      shader!.setImageSampler(0, _currentAlbedoCache!.image);
      shader!.setImageSampler(1, _currentDepthCache!.image);
      shader!.setImageSampler(2, _currentAlbedoCacheEntity!.image);
      shader!.setImageSampler(3, _currentDepthCacheEntity!.image);

      const double time = 20;
      final double lightX = cos(time) * 1;
      final double lightZ = sin(time) * 1;

      shader!.setFloatUniforms((val) {
        val.setFloats([
          _currentAlbedoCache!.width,
          _currentAlbedoCache!.height,
          _currentAlbedoCacheEntity!.width,
          _currentAlbedoCacheEntity!.height,
          _currentAlbedoCache!.unscaledPos.x - _currentAlbedoCacheEntity!.unscaledPos.x,
          _currentAlbedoCache!.unscaledPos.y - _currentAlbedoCacheEntity!.unscaledPos.y,
          0.5,
          2.5,
          20,
          0.5,
          DateTime.now().millisecondsSinceEpoch.toDouble(),
        ]);
      });
      
      shaderPaint.shader = shader;

      canvas.translate(_currentAlbedoCache!.unscaledPos.x, _currentAlbedoCache!.unscaledPos.y);
      canvas.drawRect((Vector2.zero()).toPositionedRect(imageSize + Vector2.all(viewportExtendPixels)), shaderPaint);

      if(debugRender) {
        canvas.drawRect(
            (Vector2.zero()).toPositionedRect(imageSize + Vector2.all(viewportExtendPixels)),
            Paint()
              ..color = Colors.red
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
        );

        canvas.drawRect(
            (Vector2.all(viewportExtendPixels / 2)).toPositionedRect(imageSize),
            Paint()
              ..color = Colors.green
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
        );
      }
      
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


Paint calculateDepthPaint(IsometricRenderable renderable, Paint overridePaint) {
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
  
  print("depth paint of $renderable: ${footY}");

  return overridePaint;
}