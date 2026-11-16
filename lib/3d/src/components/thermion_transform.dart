import 'package:thermion_flutter/thermion_flutter.dart'
    show FilamentApp, Matrix4, ThermionEntity;

// Sets the local transform of [entity] on thermion's render thread.
//
// This is the only place that talks to [FilamentApp.instance] for transforms,
// so switching the strategy later only needs a change here.
// Thermion recommends the render thread variant over the synchronous
// `setTransform` when transforms are set from outside the render pass, like
// Flame's update loop. The values of [transform] are copied before this call
// returns, so the matrix may be reused or modified right away.

Future<void> setTransformOnRenderThread(
  ThermionEntity entity,
  Matrix4 transform,
) => FilamentApp.instance!.transformManager.setTransformAsync(entity, transform);
