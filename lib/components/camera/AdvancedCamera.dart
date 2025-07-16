import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:mpg_achievements_app/components/player.dart';

import 'animation_style.dart';

class AdvancedCamera extends CameraComponent {
  AdvancedCamera({required World super.world, super.width = 640, super.height = 360}) : super.withFixedResolution() {}

  Player? player; //the player to follow

  Vector2 pos = Vector2.zero(); //current camera pos

  Vector2 initialPos = Vector2.zero(); //the position of the camera when it received a move task
  Vector2 givenMovePosition = Vector2.zero(); //the position the camera has to move to

  double? initialZoom; //the zoom of the camera at the beginning of the animation
  double? givenZoom; //the zoom the camera has to reach

  double timeLeft = 0; //the time left to get to the given position
  double initialGivenTime = 0; //the initial given time for getting to the position

  AnimationStyle animationStyle = AnimationStyle.Linear; // the animation style of the camera. for example 'easeOut' means

  Vector2 dir = Vector2.zero(); //the direction the camera is currently going into

  bool followPlayer = false;
  late double followAccuracy; //the distance between camera pos and player pos it needs to move the camera. so a higher value equals less frequent camera adjustments

  @override
  void moveTo(Vector2 point, {AnimationStyle animationStyle = AnimationStyle.Linear, double speed = double.infinity, double time = 0, double? zoom}) {
    if (speed == double.infinity && time == 0) { // if theres no speed and time for the camera given, we complete it instant
      pos = point;
      viewfinder.zoom = zoom??viewfinder.zoom; //if there was given a new zoom val, use it
      super.moveTo(point);
      return;
    }

    if(zoom != null) { //if a zoom is given
      initialZoom = viewfinder.zoom;
      givenZoom = zoom;
    }

    givenMovePosition = point;
    initialPos = pos.clone();

    timeLeft = time;
    initialGivenTime = time;

    this.animationStyle = animationStyle;
  }

  @override
  void follow(ReadOnlyPositionProvider target, {double maxSpeed = double.infinity, bool horizontalOnly = false, bool verticalOnly = false, bool snap = false, AnimationStyle animationStyle = AnimationStyle.Linear}) {
    super.follow(target, maxSpeed: maxSpeed, horizontalOnly: horizontalOnly, verticalOnly: verticalOnly, snap: snap);
  }

  void setFollowPlayer(bool val, {Player? player, double accuracy = 10}){ // enables following of the player. the accuracy is the distance between camera pos and player pos it needs to move the camera. so a higher value equals less frequent camera adjustments
    if(player != null) setPlayer(player);
    followPlayer = val;
    followAccuracy = accuracy;
  }

  void setPlayer(Player player){
    this.player = player;
  }

  @override
  void update(double dt) {
    if (timeLeft > 0) { //if theres an active task with time left
      timeLeft -= dt * 1000; //dt is measured in microseconds

      double timeProgress = 1 - (timeLeft / initialGivenTime); //progress of the time between 0 and 1

      timeProgress = timeProgress.clamp(0, 1); //make sure its not over or below 0 and 1

      double progressVal = switch (animationStyle) { //progress of the animation between 0 and 1. this is NOT the same as the time progress, the increase of this variable isn't constant, sometimes getting slower at the end for example
        AnimationStyle.Linear => linear(timeProgress), //constant increase
        AnimationStyle.EaseIn => easeIn(timeProgress), //slow at the beginning and fast at the end
        AnimationStyle.EaseOut => easeOut(timeProgress), //first fast and then slow
        AnimationStyle.EaseInOut => easeInOut(timeProgress), //slow -> fast -> slow
      };

      pos = Vector2(
          initialPos.x + (givenMovePosition.x - initialPos.x) * progressVal, //converting the direction and the progress of the animation into a position for the camera
          initialPos.y + (givenMovePosition.y - initialPos.y) * progressVal
      );

      if(givenZoom != null) { //if there was a zoom given, it has to be calculated aswell
        double zoom = initialZoom! + (givenZoom! - initialZoom!) * progressVal;
        moveTo(pos, zoom: zoom);
      } else moveTo(pos);



      if (timeLeft <= 0) { //if the time is over, then set the position to the given one to avoid inaccuracies
        pos = givenMovePosition;
        moveTo(pos);
      }
    } else {
      givenZoom = null; //if the animation is over we reset the zoom to null so that the next animation can also have no zoom change
    }

    if (followPlayer) { //if the camera is in follow mode we check if we need to reposition the camera to the player
      if (viewfinder.position.distanceTo(player!.position) > followAccuracy) {
        moveTo(player!.absoluteCenter, time: 1000, animationStyle: AnimationStyle.EaseOut);
      }
    }

    super.update(dt);
  }
}