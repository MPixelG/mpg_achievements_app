import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';

import '../../mpg_pixel_adventure.dart';
import '../camera/AdvancedCamera.dart';

class CameraAwareLightingRenderer {
  late FragmentShader lightingShader;
  bool isShaderReady = false;

  Vector2 lightWorldPosition = Vector2.zero();
  Vector2 playerWorldPosition = Vector2.zero();
  List<Rect> shadowObjectsWorld = [];

  Future<void> initializeShader() async {
    try {
      final program = await FragmentProgram.fromAsset(
        "assets/shaders/lighting.glsl",
      );
      lightingShader = program.fragmentShader();
      isShaderReady = true;
      print("Camera-aware lighting shader loaded!");
    } catch (e) {
      print("Lighting shader error: $e");
      isShaderReady = false;
    }
  }

  void addShadowObjectWorld(
    double worldX,
    double worldY,
    double width,
    double height,
  ) {
    shadowObjectsWorld.add(Rect.fromLTWH(worldX, worldY, width, height));
  }

  void extractObjectsFromTiledMap(TiledComponent tiledMap) {
    shadowObjectsWorld.clear();

    for (final objectGroup in tiledMap.tileMap.renderableLayers.where(
      (element) => element.layer is ObjectGroup,
    )) {
      for (final object in (objectGroup.layer as ObjectGroup).objects) {
        shadowObjectsWorld.add(
          Rect.fromLTWH(object.x, object.y, object.width, object.height),
        );
      }
    }

    print(
      "Found ${shadowObjectsWorld.length} shadow objects in world coordinates",
    );
    print("Layers: " + tiledMap.tileMap.renderableLayers.toString());
  }

  void updateWorldPositions(Vector2 playerWorldPos, Vector2 lightWorldPos) {
    playerWorldPosition = playerWorldPos;
    lightWorldPosition = lightWorldPos;
  }

  Vector2 worldToScreen(
    Vector2 worldPos,
    AdvancedCamera camera,
    Vector2 screenSize,
  ) {
    final cameraPos = camera.pos;
    final zoom = camera.viewfinder.zoom;

    final relative = (worldPos - cameraPos) * zoom;

    final screenPixel = screenSize / 2 + relative;

    return Vector2(screenPixel.x / screenSize.x, screenPixel.y / screenSize.y);
  }

  Rect worldRectToScreen(
    Rect worldRect,
    AdvancedCamera camera,
    Vector2 screenSize,
  ) {
    final topLeft = worldToScreen(
      Vector2(worldRect.left, worldRect.top),
      camera,
      screenSize,
    );
    final bottomRight = worldToScreen(
      Vector2(worldRect.right, worldRect.bottom),
      camera,
      screenSize,
    );

    return Rect.fromLTRB(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y);
  }

  void updateShaderUniforms(
    AdvancedCamera camera,
    Vector2 screenSize,
    double gameTime,
  ) {
    if (!isShaderReady) return;

    try {
      Vector2 playerScreen = worldToScreen(
        playerWorldPosition,
        camera,
        screenSize,
      );
      Vector2 lightScreen = worldToScreen(
        lightWorldPosition,
        camera,
        screenSize,
      );

      int paramIndex = 0;

      lightingShader.setFloat(paramIndex++, screenSize.x);
      lightingShader.setFloat(paramIndex++, screenSize.y);
      lightingShader.setFloat(paramIndex++, playerScreen.x);
      lightingShader.setFloat(paramIndex++, playerScreen.y);
      lightingShader.setFloat(paramIndex++, lightScreen.x);
      lightingShader.setFloat(paramIndex++, lightScreen.y);
      lightingShader.setFloat(paramIndex++, gameTime);

      int objectCount = shadowObjectsWorld.length.clamp(0, 5);
      lightingShader.setFloat(paramIndex++, objectCount.toDouble());

      for (int i = 0; i < 5; i++) {
        if (i < shadowObjectsWorld.length) {
          Rect worldRect = shadowObjectsWorld[i];
          Rect screenRect = worldRectToScreen(worldRect, camera, screenSize);

          double centerX = screenRect.left + screenRect.width / 2;
          double centerY = screenRect.top + screenRect.height / 2;

          lightingShader.setFloat(paramIndex++, centerX);
          lightingShader.setFloat(paramIndex++, centerY);
          lightingShader.setFloat(paramIndex++, screenRect.width);
          lightingShader.setFloat(paramIndex++, screenRect.height);
        } else {
          // Leere Objekte
          lightingShader.setFloat(paramIndex++, 0.0);
          lightingShader.setFloat(paramIndex++, 0.0);
          lightingShader.setFloat(paramIndex++, 0.0);
          lightingShader.setFloat(paramIndex++, 0.0);
        }
      }
    } catch (e) {
      print("Error updating camera-aware lighting: $e");
    }
  }

  void renderLighting(
    Canvas canvas,
    AdvancedCamera camera,
    Vector2 screenSize,
    double gameTime,
  ) {
    if (!isShaderReady) return;

    updateShaderUniforms(camera, screenSize, gameTime);

    final paint = Paint()
      ..shader = lightingShader
      ..blendMode = BlendMode.multiply;

    canvas.drawRect(Rect.fromLTWH(0, 0, screenSize.x, screenSize.y), paint);
  }

  void renderDebugObjects(
    Canvas canvas,
    AdvancedCamera camera,
    Vector2 screenSize,
  ) {
    final debugPaint = Paint()
      ..color = Colors.red.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (Rect worldRect in shadowObjectsWorld) {
      Rect screenRect = worldRectToScreen(worldRect, camera, screenSize);

      if (screenRect.left < 1.0 &&
          screenRect.right > 0.0 &&
          screenRect.top < 1.0 &&
          screenRect.bottom > 0.0) {
        canvas.drawRect(
          Rect.fromLTWH(
            screenRect.left * screenSize.x,
            screenRect.top * screenSize.y,
            screenRect.width * screenSize.x,
            screenRect.height * screenSize.y,
          ),
          debugPaint,
        );
      }
    }
  }
}

class PixelAdventureWithCameraLighting extends PixelAdventure {
  late CameraAwareLightingRenderer lightingRenderer;
  bool debugMode = false;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    lightingRenderer = CameraAwareLightingRenderer();
    await lightingRenderer.initializeShader();

    lightingRenderer.addShadowObjectWorld(200, 400, 300, 50); // Plattform
    lightingRenderer.addShadowObjectWorld(600, 300, 100, 200); // Wand
    lightingRenderer.addShadowObjectWorld(
      900,
      500,
      200,
      30,
    ); // Weitere Plattform

    debugMode = true;

    // if (level.tiledMap != null) {
    //   lightingRenderer.extractObjectsFromTiledMap(level.tiledMap);
    // }
  }

  @override
  void update(double dt) {
    super.update(dt);

    Vector2 playerWorldPos = player.position;

    Vector2 lightWorldPos = Vector2(playerWorldPos.x, playerWorldPos.y);

    lightingRenderer.updateWorldPositions(playerWorldPos, lightWorldPos);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (debugMode) {
      lightingRenderer.renderDebugObjects(canvas, cam, size);
    }

    double currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    lightingRenderer.renderLighting(canvas, cam, size, currentTime);
  }

  void toggleDebugMode() {
    debugMode = !debugMode;
  }
}
