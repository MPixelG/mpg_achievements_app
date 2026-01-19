import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/3d/src/game.dart';
import 'package:mpg_achievements_app/main.dart';
import 'package:thermion_flutter/thermion_flutter.dart';


class GameScreen3d extends StatefulWidget {
  const GameScreen3d({super.key, required this.title});
  final String title;

  @override
  State<GameScreen3d> createState() => _GameScreen3dState();
}

class _GameScreen3dState extends State<GameScreen3d> with WidgetsBindingObserver{
  ThermionViewer? _thermionViewer;
  PixelAdventure3D get _flameGame => PixelAdventure3D.currentInstance;
  bool _is3DReady = false;
  bool _isLoading = false;
  bool _isSceneLoaded = false;

  @override
  void initState() {
    super.initState();
    //Lifecycle des Widgets wird überwacht, wegen potentiellem Bufferüberlauf wenn im Hintergrund
    WidgetsBinding.instance.addObserver(this);
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
      const double dist = 2.0;
      const double zoom = 0.1;
      double aspect = 1.0;
      final Vector3 position = Vector3(20,20,20); //Isometric corner
      final Vector3 target = Vector3(0,0,0); //Center of level
      final Vector3 standardYUp = Vector3(0, 1, 0);

      _flameGame.setThermionViewer(viewer);

      //camera settings isometric
      final camera = await viewer.getActiveCamera();
      await camera.lookAt(position,focus: target,up: standardYUp);
      await camera.setProjection(
          Projection.Perspective,
          -zoom*aspect, //left
          zoom*aspect,  //right
          -zoom,        //bottom
          zoom,         //top
          0.1, 1000.0   // Near/Far clipping planes
      );
      await viewer.setPostProcessing(true);
      await viewer.setRendering(true);

      if (mounted) {
        setState(() {
          // Use the actual widget size if possible, or screen size as fallback to make the shapes look correctly
          //gets the screen or window size
          final size = MediaQuery.of(context).size;
          if (size.height > 0) {
            aspect = size.width / size.height;
          }
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
    // Lifecycle Observer entfernen
    WidgetsBinding.instance.removeObserver(this);
    _thermionViewer?.setRendering(false);
    _thermionViewer?.dispose();
    super.dispose();
  }

  //handled Lifecyclemanagement z.B. wenn Spiel im Background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_thermionViewer == null) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _thermionViewer!.setRendering(false);
    } else if (state == AppLifecycleState.resumed) {
      _thermionViewer!.setRendering(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Scaffold out = Scaffold(
      backgroundColor: Colors.black,
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
          //Layer 3 -> FlameGame
          if (_is3DReady)
            Positioned.fill(
              child: RiverpodAwareGameWidget<PixelAdventure3D>(
                  key: gameWidgetKey, // Good practice
                  game: _flameGame,
                  // Your existing Overlay mapping
                  overlayBuilderMap: _flameGame.buildOverlayMap()
              ),
            ),
        ],
      ),
    );
    if(!_isLoading && !_is3DReady) _loadAssets();
    return out;
  }
}
