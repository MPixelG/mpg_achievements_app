import 'dart:ui';

import 'package:flame/src/anchor.dart';
import 'package:flame/src/cache/images.dart';
import 'package:flame/src/flame.dart';
import 'package:flame/src/image_composition.dart';
import 'package:flame/src/palette.dart';
import 'package:mpg_achievements_app/util/type_utils.dart';

/// A [Sprite] is a region of an [Image] that can be rendered in the Canvas.
///
/// It might represent the entire image or be one of the pieces a spritesheet is
/// composed of. It holds a reference to the source image from which the region
/// is extracted, and the [src] rectangle is the portion inside that image that
/// is to be rendered (not to be confused with the `dest` rect, which is where
/// in the Canvas the sprite is rendered).
/// It also has a [paint] field that can be overwritten to apply a tint to this
/// [Sprite] (default is white, meaning no tint).
class GameSprite {
  Paint paint = BasicPalette.white.paint();
  Image albedoImage;
  Image depthImage;
  Rect src = Rect.zero;
  Rect? srcDepth = Rect.zero;

  GameSprite(
      this.albedoImage,
      this.depthImage, {
        Vector2? srcPosition,
        Vector2? srcPositionDepth,
        Vector2? srcSize,
        Vector2? srcSizeDepth,
      }) {
    this.srcSize = srcSize;
    this.srcPosition = srcPosition;
    
    if(srcPositionDepth != srcPosition) this.srcPositionDepth = srcPositionDepth;
    if(srcSizeDepth != srcSize) this.srcSizeDepth = srcSizeDepth;
  }

  /// Takes a path of an image, a [srcPosition] and [srcSize] and loads the
  /// sprite animation.
  /// When the [images] is omitted, the global [Flame.images] is used.
  static Future<GameSprite> load(
      String src, {
        Vector2? srcPosition,
        Vector2? srcSize,
        Images? images,
      }) async {
    final imagesCache = images ?? Flame.images;
    final albedoImage = await imagesCache.load(src);
    final depthImage = await imagesCache.load(src);
    return GameSprite(albedoImage, depthImage, srcPosition: srcPosition, srcSize: srcSize);
  }

  double get _imageWidth => albedoImage.width.toDouble();

  double get _imageHeight => albedoImage.height.toDouble();

  Vector2 get originalSize => Vector2(_imageWidth, _imageHeight);

  Vector2 get srcSize => Vector2(src.width, src.height);
  Vector2 get srcSizeDepth => Vector2(srcDepth?.width ?? src.width, srcDepth?.height ?? src.height);

  set srcSize(Vector2? size) {
    final actualSize = size ?? albedoImage.size;
    src = srcPosition.toPositionedRect(actualSize);
  }

  set srcSizeDepth(Vector2? size) {
    final actualSize = size ?? depthImage.size;
    srcDepth = srcPositionDepth.toPositionedRect(actualSize);
  }

  Vector2 get srcPosition => src.topLeft.toVector2();
  Vector2 get srcPositionDepth => srcDepth?.topLeft.toVector2() ?? src.topLeft.toVector2();

  set srcPosition(Vector2? position) {
    src = (position ?? Vector2.zero()).toPositionedRect(srcSize);
  }

  set srcPositionDepth(Vector2? position) {
    srcDepth = (position ?? Vector2.zero()).toPositionedRect(srcSizeDepth);
  }

  String _createAlbedoRasterizeCacheKey() => '${albedoImage.hashCode}-${srcPosition.x}-'
        '${srcPosition.y}-${srcSize.x}-${srcSize.y}';  
  String _createDepthRasterizeCacheKey() => '${depthImage.hashCode}-${srcPosition.x}-'
        '${srcPosition.y}-${srcSize.x}-${srcSize.y}';

  /// Returns a new [Sprite] where the image in memory is just the region
  /// defined by the original sprite.
  ///
  /// If the [images] argument is passed it will be used to cache the
  /// rasterized image, otherwise the global [Flame.images] will be used.
  /// If the [cacheKey] is passed in, that will be the key for the cached image,
  /// otherwise the hash code of the rasterized image will be used as the key.
  Future<GameSprite> rasterize({String? albedoCacheKey, String? depthCacheKey, Images? images}) async {
    final albedoKey = albedoCacheKey ?? _createAlbedoRasterizeCacheKey();
    final depthKey = depthCacheKey ?? _createDepthRasterizeCacheKey();

    final imagesCache = images ?? Flame.images;
    
    final Image albedoImage;
    if (imagesCache.containsKey(albedoKey)) {
      albedoImage = imagesCache.fromCache(albedoKey);
    } else {
      albedoImage = await toAlbedoImage();
      imagesCache.add(albedoKey, albedoImage);
    }

    final Image depthImage;
    if (imagesCache.containsKey(depthKey)) {
      depthImage = imagesCache.fromCache(depthKey);
    } else {
      depthImage = await toDepthImage();
      imagesCache.add(depthKey, depthImage);
    }
    
    

    return GameSprite(
      albedoImage,
      depthImage,
      srcSize: srcSize,
    );
  }

  /// Same as [render], but takes both the position and the size as a single
  /// [Rect].
  ///
  /// **Note**: only use this if you are already using [Rect]'s to represent
  /// both the position and dimension of your [Sprite]. If you are using
  /// [Vector2]s, prefer the other method.
  void renderRect(
      Canvas canvas,
      Canvas depthCanvas,
      Rect albedoRect,
      Rect depthRect, {
        Paint? overrideAlbedoPaint,
        Paint? overrideDepthPaint,
      }) {
    render(
      canvas,
      depthCanvas,
      albedoPosition: albedoRect.topLeft.toVector2(),
      albedoSize: albedoRect.size.toVector2(),
      depthPosition: depthRect.topLeft.toVector2(),
      depthSize: depthRect.size.toVector2(),
      overridePaintAlbedo: overrideAlbedoPaint,
      overridePaintDepth: overrideDepthPaint,
    );
  }

  // Used to avoid the creation of new Vector2 objects in render.
  static final _tmpAlbedoRenderPosition = Vector2.zero();
  static final _tmpDepthRenderPosition = Vector2.zero();
  static final _tmpAlbedoRenderSize = Vector2.zero();
  static final _tmpDepthRenderSize = Vector2.zero();
  static final _zeroPosition = Vector2.zero();

  /// Renders this sprite onto the [canvas].
  ///
  /// * [position]: x,y coordinates where it will be drawn; default to origin.
  /// * [size]: width/height dimensions; it can be bigger or smaller than the
  ///   original size -- but it defaults to the original texture size.
  /// * [anchor]: where in the sprite the x/y coordinates refer to; defaults to
  ///   topLeft.
  /// * [overridePaint]: paint to use. You can also change the paint on your
  ///   Sprite instance. Default is white.
  void render(
      Canvas albedoCanvas,
      Canvas depthCanvas, {
        Vector2? albedoPosition,
        Vector2? albedoPositionSrc,
        Vector2? depthPosition,
        Vector2? depthPositionSrc,
        Vector2? albedoSize,
        Vector2? albedoSizeSrc,
        Vector2? depthSize,
        Vector2? depthSizeSrc,
        Anchor anchor = Anchor.topLeft,
        Paint? overridePaintAlbedo,
        Paint? overridePaintDepth,
      }) {
    if (albedoPosition != null) {
      _tmpAlbedoRenderPosition.setFrom(albedoPosition);
    } else {
      _tmpAlbedoRenderPosition.setZero();
    }

    if (depthPosition != null) {
      _tmpDepthRenderPosition.setFrom(depthPosition);
    } else {
      _tmpDepthRenderPosition.setZero();
    }

    _tmpAlbedoRenderSize.setFrom(albedoSize ?? srcSize);
    _tmpDepthRenderSize.setFrom(depthSize ?? srcSize);

    _tmpAlbedoRenderPosition.setValues(
      _tmpAlbedoRenderPosition.x - (anchor.x * _tmpAlbedoRenderSize.x),
      _tmpAlbedoRenderPosition.y - (anchor.y * _tmpAlbedoRenderSize.y),
    );

    _tmpDepthRenderPosition.setValues(
      _tmpDepthRenderPosition.x - (anchor.x * _tmpDepthRenderSize.x),
      _tmpDepthRenderPosition.y - (anchor.y * _tmpDepthRenderSize.y),
    );

    final drawRectAlbedo = _tmpAlbedoRenderPosition.toPositionedRect(_tmpAlbedoRenderSize);
    final drawRectDepth = _tmpDepthRenderPosition.toPositionedRect(_tmpDepthRenderSize);
    final drawPaintAlbedo = overridePaintAlbedo ?? paint;
    final drawPaintDepth = overridePaintDepth ?? Paint();



    final srcRectAlbedo = (albedoPositionSrc ?? anchor*srcSize).toPositionedRect(albedoSizeSrc ?? srcSize);
    final srcRectDepth = (depthPositionSrc ?? anchor*(srcDepth?.size.toVector2() ?? srcSize)).toPositionedRect(depthSizeSrc ?? srcDepth?.size.toVector2() ?? srcSize);

    albedoCanvas.drawImageRect(albedoImage, srcRectAlbedo, drawRectAlbedo, drawPaintAlbedo);
    depthCanvas.drawImageRect(depthImage, srcRectAlbedo, drawRectDepth, drawPaintDepth);
  }

  /// Return a new [Image] based on the [src] of the Sprite.
  ///
  /// **Note:** This is a heavy async operation and should not be called inside
  /// the game loop. Remember to call dispose on the [Image] object once you
  /// aren't going to use it anymore.
  Future<Image> toAlbedoImage() {
    final composition = ImageComposition()
      ..add(albedoImage, _zeroPosition, source: src);
    return composition.compose();
  }  
  Future<Image> toDepthImage() {
    final composition = ImageComposition()
      ..add(depthImage, _zeroPosition, source: srcDepth ?? src);
    return composition.compose();
  }

  /// Return a new [Image] based on the [src] of the Sprite.
  ///
  /// A sync version of the [toImage] function. Read [Picture.toImageSync] for a
  /// detailed description of possible benefits in performance.
  Image toAlbedoImageSync() {
    final composition = ImageComposition()
      ..add(albedoImage, _zeroPosition, source: src);
    return composition.composeSync();
  }  
  
  Image toDepthImageSync() {
    final composition = ImageComposition()
      ..add(depthImage, _zeroPosition, source: srcDepth ?? src);
    return composition.composeSync();
  }
  
  
  void dispose(){
    albedoImage.dispose();
    depthImage.dispose();
  }
}