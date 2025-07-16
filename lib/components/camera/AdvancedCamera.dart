import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:mpg_achievements_app/components/camera/animation_style.dart';
import 'package:mpg_achievements_app/components/player.dart';

class AdvancedCamera extends CameraComponent {
  AdvancedCamera({required World super.world, super.width = 640, super.height = 360}) : super.withFixedResolution() {}

  Player? player;

  Vector2 pos = Vector2.zero();

  Vector2 initialPos = Vector2.zero();
  Vector2 givenMovePosition = Vector2.zero();

  double timeLeft = 0;
  double initialGivenTime = 0;

  AnimationStyle animationStyle = AnimationStyle.Linear;

  Vector2 dir = Vector2.zero();

  bool followPlayer = false;
  late double followAccuracy;


  @override
  void moveTo(Vector2 point, {AnimationStyle animationStyle = AnimationStyle.Linear, double speed = double.infinity, double time = 0}) {
    if (speed == double.infinity && time == 0) {
      pos = point;
      super.moveTo(point);
      return;
    }

    givenMovePosition = point;
    initialPos = pos;
    timeLeft = time;
    initialGivenTime = time;

    this.animationStyle = animationStyle;
  }

  @override
  void follow(ReadOnlyPositionProvider target, {double maxSpeed = double.infinity, bool horizontalOnly = false, bool verticalOnly = false, bool snap = false, AnimationStyle animationStyle = AnimationStyle.Linear}) {
    super.follow(target, maxSpeed: maxSpeed, horizontalOnly: horizontalOnly, verticalOnly: verticalOnly, snap: snap);
  }

  void setFollowPlayer(bool val, {Player? player, double accuracy = 10}){
    if(player != null) setPlayer(player);
    followPlayer = val;
    followAccuracy = accuracy;
  }

  void setPlayer(Player player){
    this.player = player;
  }
  @override
  void update(double dt) {
    if (timeLeft > 0) {
      timeLeft -= dt * 1000;
      double timeProgress = 1 - (timeLeft / initialGivenTime);

      timeProgress = timeProgress.clamp(0, 1);

      double progressVal = switch (animationStyle) {
        AnimationStyle.Linear => linear(timeProgress),
        AnimationStyle.EaseIn => easeIn(timeProgress),
        AnimationStyle.EaseOut => easeOut(timeProgress),
        AnimationStyle.EaseInOut => easeInOut(timeProgress),
      };

      pos = Vector2(
          initialPos.x + (givenMovePosition.x - initialPos.x) * progressVal,
          initialPos.y + (givenMovePosition.y - initialPos.y) * progressVal
      );


      moveTo(pos);


      if (timeLeft <= 0) {
        pos = givenMovePosition;
        moveTo(pos);
      }
    }

    if (followPlayer)

    super.update(dt);
  }
}