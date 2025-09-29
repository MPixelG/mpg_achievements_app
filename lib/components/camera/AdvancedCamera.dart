import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:mpg_achievements_app/components/entity/player.dart';

import '../animation/animation_style.dart';

class AdvancedCamera extends CameraComponent {
  AdvancedCamera({
    required World super.world,
    super.width = 640,
    super.height = 360,
  }) : super.withFixedResolution();

  Player? player; //the player to follow

  Vector2 pos = Vector2.zero(); //current camera pos

  Vector2 initialPos =
      Vector2.zero(); //the position of the camera when it received a move task
  Vector2 givenMovePosition =
      Vector2.zero(); //the position the camera has to move to

  double?
  initialZoom; //the zoom of the camera at the beginning of the animation
  double? givenZoom; //the zoom the camera has to reach

  double timeLeft = 0; //the time left to get to the given position (seconds)
  double initialGivenTime =
      0; //the initial given time for getting to the position (seconds)

  AnimationStyle animationStyle = AnimationStyle
      .linear; // the animation style of the camera. for example 'easeOut' means

  Vector2 dir =
      Vector2.zero(); //the direction the camera is currently going into

  Vector2 shakingPosition = Vector2.zero();
  late double shakingAmount = 0;
  late double shakingTime = 0;
  late double totalShakingTime = 0;
  late AnimationStyle shakingAnimation;

  bool followPlayer = false;
  late double
  followAccuracy; //the distance between camera pos and player pos it needs to move the camera. so a higher value equals less frequent camera adjustments

  Vector2 boundsMin = Vector2.zero();
  Vector2 boundsMax = Vector2.all(double.infinity);

  @override
  void moveTo(
    Vector2 point, {
    AnimationStyle animationStyle = AnimationStyle.linear,
    double speed = double.infinity,
    double time = 0,
    double? zoom,
  }) {
    Vector2? boundsMinRelative;
    Vector2? boundsMaxRelative;

    point.clamp(boundsMinRelative ?? Vector2.all(double.negativeInfinity), boundsMaxRelative ?? Vector2.all(double.infinity));

    if (speed == double.infinity && time == 0) {
      // if theres no speed and time for the camera given, we complete it instant
      pos = point;
      viewfinder.zoom =
          zoom ?? viewfinder.zoom; //if there was given a new zoom val, use it
      // apply once (avoid multiple moveTo/moveBy calls per frame)
      viewfinder.position = pos;
      return;
    }

    if (zoom != null) {
      //if a zoom is given
      initialZoom = viewfinder.zoom;
      givenZoom = zoom;
    }

    givenMovePosition = point;
    initialPos = pos.clone();

    // convert incoming time (ms in original API) to seconds for dt consistency
    timeLeft = time > 0 ? time / 300.0 : 0.0; //seconds
    initialGivenTime = timeLeft;

    this.animationStyle = animationStyle;
  }

  @override
  void follow(
    ReadOnlyPositionProvider target, {
    double maxSpeed = double.infinity,
    bool horizontalOnly = false,
    bool verticalOnly = false,
    bool snap = false,
    AnimationStyle animationStyle = AnimationStyle.linear,
  }) {
    super.follow(
      target,
      maxSpeed: maxSpeed,
      horizontalOnly: horizontalOnly,
      verticalOnly: verticalOnly,
      snap: snap,
    );
  }

  void setMoveBounds(Vector2 min, Vector2 max) {
    boundsMin = min;
    boundsMax = max;
  }

  void setFollowPlayer(bool val, {Player? player, double accuracy = 10}) {
    // enables following of the player. the accuracy is the distance between camera pos and player pos it needs to move the camera. so a higher value equals less frequent camera adjustments
    if (player != null) setPlayer(player);
    followPlayer = val;
    followAccuracy = accuracy;
  }

  void setPlayer(Player player) {
    this.player = player;
  }

  void shakeCamera(
    double shakingAmount,
    double shakingTime, {
    AnimationStyle animationStyle = AnimationStyle.easeOut,
  }) {
    this.shakingAmount = shakingAmount;
    this.shakingTime = shakingTime;
    totalShakingTime = shakingTime;
    shakingAnimation = animationStyle;
  }

  late Vector2 centeredCamPos;

  // easing helpers
  double linear(double t, {double startVal = 0, double endVal = 1}) =>
      startVal + (endVal - startVal) * t;
  double easeIn(double t, {double startVal = 0, double endVal = 1}) =>
      startVal + (endVal - startVal) * (t * t);
  double easeOut(double t, {double startVal = 0, double endVal = 1}) =>
      startVal + (endVal - startVal) * (1 - (1 - t) * (1 - t));
  double easeInOut(double t, {double startVal = 0, double endVal = 1}) =>
      startVal +
      (endVal - startVal) *
          ((t < 0.5) ? (2 * t * t) : (1 - 2 * (1 - t) * (1 - t)));

  Vector2 _shakeOffset(double strength) {
    // deterministic smooth offset to avoid frame-to-frame jitter (sinusoids based on time)
    final now = DateTime.now().microsecondsSinceEpoch.toDouble();
    final dx = strength * ((sin(now * 0.00007)));
    final dy = strength * ((cos(now * 0.00009)));
    return Vector2(dx, dy);
  }

  @override
  void update(double dt) {
    if (timeLeft > 0) {
      //if theres an active task with time left
      timeLeft -= dt; //dt is seconds in Flame

      double timeProgress =
          1 -
          (timeLeft / initialGivenTime); //progress of the time between 0 and 1

      timeProgress = timeProgress.clamp(
        0,
        1,
      ); //make sure its not over or below 0 and 1

      double progressVal = switch (animationStyle) {
        //progress of the animation between 0 and 1. this is NOT the same as the time progress, the increase of this variable isn't constant, sometimes getting slower at the end for example
        AnimationStyle.linear => linear(timeProgress), //constant increase
        AnimationStyle.easeIn => easeIn(
          timeProgress,
        ), //slow at the beginning and fast at the end
        AnimationStyle.easeOut => easeOut(
          timeProgress,
        ), //first fast and then slow
        AnimationStyle.easeInOut => easeInOut(
          timeProgress,
        ), //slow -> fast -> slow
      };

      pos = Vector2(
        initialPos.x +
            (givenMovePosition.x - initialPos.x) *
                progressVal, //converting the direction and the progress of the animation into a position for the camera
        initialPos.y + (givenMovePosition.y - initialPos.y) * progressVal,
      );

      if (givenZoom != null) {
        //if there was a zoom given, it has to be calculated aswell
        double zoom = initialZoom! + (givenZoom! - initialZoom!) * progressVal;
        viewfinder.zoom = zoom;
      }

      if (timeLeft <= 0) {
        //if the time is over, then set the position to the given one to avoid inaccuracies
        pos = givenMovePosition;
        timeLeft = 0;
        initialGivenTime = 0;
        givenZoom = null;
      }
    } else {
      givenZoom =
          null; //if the animation is over we reset the zoom to null so that the next animation can also have no zoom change
    }

    if (followPlayer) {
      //if the camera is in follow mode we check if we need to reposition the camera to the player
      if (player != null &&
          viewfinder.position.distanceTo(player!.position) > followAccuracy) {
        // use a short smooth move instead of instant set to avoid small jumps
        moveTo(
          player!.absoluteCenter,
          time: 250,
          animationStyle: AnimationStyle.easeOut,
        );
      }
    }

    if (shakingTime > 0) {
      //if theres an ongoing shaking animation

      double ratio = (shakingTime / totalShakingTime).clamp(0.0, 1.0);
      double power = switch (shakingAnimation) {
        AnimationStyle.easeIn => easeIn(
          1 - ratio,
          startVal: shakingAmount,
          endVal: 0,
        ), //basically the same as the moving of the camera
        AnimationStyle.easeOut => easeOut(
          1 - ratio,
          startVal: shakingAmount,
          endVal: 0,
        ),
        AnimationStyle.linear => linear(
          1 - ratio,
          startVal: shakingAmount,
          endVal: 0,
        ),
        AnimationStyle.easeInOut => easeInOut(
          1 - ratio,
          startVal: shakingAmount,
          endVal: 0,
        ),
      };

      shakingPosition = _shakeOffset(power); //get the actual values

      // apply shake as final offset to avoid multiple moveBy/moveTo calls
      viewfinder.position = pos + shakingPosition;
      shakingTime -= dt; //decrease the time
    } else {
      shakingPosition = Vector2.zero();
      viewfinder.position = pos;
    }

    super.update(dt);
  }
}
