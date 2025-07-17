
import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart' hide Image;
import 'package:flame/particles.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:mpg_achievements_app/components/level.dart';
import 'dart:ui' show Image;

import 'package:mpg_achievements_app/components/physics/collisions.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

ParticleSystemComponent generateConfetti(Vector2 pos){
  Particle particle = Particle.generate(
    count: 5000,
    generator: (i) {
      Vector2 position = Vector2.zero();
      Vector2 velocity = randomVector2();
      const double gravity = .2;
      double color = Random().nextDouble() * .3;
      Paint paint = Paint()..color = Colors.primaries.elementAt(Random().nextInt(Colors.primaries.length));
      double size = Random().nextDouble() * 15;
      int angle = Random().nextInt(360);

      return ComputedParticle(
        renderer: (canvas, _) {
          velocity.y += gravity;
          velocity *= 0.94 + (size / 200);
          position += velocity;
          angle += (size / 200).toInt();
          canvas.rotate(radians(angle.toDouble()));
          canvas.drawRect(Rect.fromCenter(center: Offset(position.x + pos.x, position.y + pos.y), width: size, height: size), paint);
        }
      );
    },
    lifespan: 8,
    applyLifespanToChildren: true
  );

  return ParticleSystemComponent(particle: particle);
}


Vector2 randomVector2() => (Vector2.random() - Vector2.random()) * 20;