import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/dialogue_screen.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/text_overlay.dart';
import 'package:mpg_achievements_app/main.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:thermion_flutter/thermion_flutter.dart';

class GameScreen3d extends StatefulWidget {
  const GameScreen3d({super.key, required this.title});
  final String title;

  @override
  State<GameScreen3d> createState() => _GameScreen3dState();
}

class _GameScreen3dState extends State<GameScreen3d> {
  ThermionViewer? _thermionViewer;
  final PixelAdventure _flameGame = PixelAdventure.currentInstance;
  bool _is3DReady = false;
  bool _isLoading = false;
  bool _isSceneLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return; // prtection form doucle executiion
    setState(() {
      _isLoading = true;
    });

    // A [ThermionViewer] is the main interface for controlling asset loading,
    // rendering, camera and lighting. todo logic planning and distinction
    // Only a single instance can be active at a given time; trying to construct
    // a new instance before the old instance has been disposed will throw an exception.
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      final viewer = await ThermionFlutterPlugin.createViewer();

      if (mounted) {
        setState(() {
          _thermionViewer = viewer;
          _isLoading = false;
        });
      } else {
        await viewer.dispose();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Loading 3D Viewer mistake: $e");
      }
    }
  }

  Widget _loadButton() => Center(
    child: ElevatedButton(onPressed: _load, child: const Text("Load")),
  );

  Future<void> _loadAssets() async {
    final viewer = _thermionViewer;
    if (viewer == null) return;

    //show loader immediately
    setState(() {
      _isLoading = true;
    });

    try {
      _flameGame.setThermionViewer(viewer);
      await viewer.loadGltf("assets/3D/FlightHelmet.glb");
      await viewer.loadSkybox('assets/3D/default_env_skybox.ktx');
      await viewer.loadIbl('assets/3D/default_env_ibl.ktx');
      final camera = await viewer.getActiveCamera();
      await camera.lookAt(Vector3(0, 0, 5));
      await viewer.setPostProcessing(true);

      await viewer.setRendering(true);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSceneLoaded = true;
          _is3DReady = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading 3D assets: $e");
      }
    }
  }

  @override
  void dispose() {
    _thermionViewer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: Stack(
      children: [
        //layer 1 -> ThermionViewer
        if (_thermionViewer != null)
          Positioned.fill(child: ThermionWidget(viewer: _thermionViewer!)),
        // Layer 2: The Loading Indicator
        if (_isLoading)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  "Loading 3D viewer...",
                  style: TextStyle(color: Colors.white, fontFamily: "Roboto"),
                ),
              ],
            ),
          ),
        // Layer 3-> The Load Button
        if (_thermionViewer != null && !_isLoading && !_isSceneLoaded)
          Center(
            child: ElevatedButton(
              onPressed: _loadAssets,
              child: const Text("Load 3D Scene"),
            ),
          ),
        //Layer 4 -> FlameGame
        if (_is3DReady)
          Positioned.fill(
            child: RiverpodAwareGameWidget<PixelAdventure>(
              key: gameWidgetKey, // Good practice
              game: _flameGame,
              // Your existing Overlay mapping
              overlayBuilderMap: {
                'TextOverlay': (context, game) => TextOverlay(
                  game: game,
                  onTextOverlayDone: () {
                    game.overlays.remove("TextOverlay");
                  },
                ),
                'DialogueScreen': (context, game) => DialogueScreen(
                  game: game,
                  onDialogueFinished: () {
                    game.overlays.remove('DialogueScreen');
                  },
                  yarnFilePath: 'assets/yarn/test.yarn',
                ),
              },
            ),
          ),
      ],
    ),
  );
}
