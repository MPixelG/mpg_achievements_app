import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart' hide Image;
import 'package:flame/particles.dart';
import 'package:flutter/material.dart' hide Image;

// Function to generate a confetti particle system at a specific position (Vector2 pos)
ParticleSystemComponent generateConfetti(Vector2 pos, {int amount = 200}) {
  // Create a Particle system with a defined number of particles
  Particle particle = Particle.generate(
    count:
        amount, //low-end/older devices like mine have problems with this amount of particles
    generator: (i) {
      Vector2 position = Vector2.zero();
      Vector2 velocity = randomVector2() * 0.7; //generates random velocity
      const double gravity = .2;
      // Randomly choose a color from the Colors.primaries list (Flutter’s built-in primary color palette)
      Paint paint = Paint()
        ..color = Colors.primaries.elementAt(
          Random().nextInt(Colors.primaries.length),
        );
      // Random size for each confetti piece (between 0 and 15 pixels)
      double size = Random().nextDouble() * 12 + 5;
      // Random angle for the rotation of each confetti piece
      int angle = Random().nextInt(360);

      // Return a ComputedParticle with custom rendering logic
      return ComputedParticle(
        renderer: (unrotatedCanvas, _) {
          // Apply gravity to the vertical velocity of the particle
          velocity.y += gravity * (size / 10);
          // Apply slight friction or air resistance to slow the particle over time
          velocity *=
              0.94 +
              (size /
                  200); // The larger the confetti, the slower it will move (based on size)
          position +=
              velocity; // Update the position of the particle based on its velocity
          angle += (size / 200)
              .toInt(); // Change the angle of the particle slightly based on its size (larger particles rotate more)

          unrotatedCanvas.renderRotated(angle.toDouble(), position + pos, (
            canvas,
          ) {
            canvas.drawRect(
              Rect.fromCenter(
                center: Offset(position.x + pos.x, position.y + pos.y),
                width: size,
                height: size,
              ),
              paint,
            );
          });

          // Draw the particle as a rectangle centered at its position
          // `position.x + pos.x` and `position.y + pos.y` ensure the confetti appears at the given `pos` offset
        },
      );
    },
    lifespan: 8,
    // Ensures that the lifespan of each particle is applied to its child particles as well
    applyLifespanToChildren: true,
  );
  //Return the particle system component to be added to the game
  return ParticleSystemComponent(particle: particle);
}

// Used for velocity generation Helper function to generate a random Vector2 velocity with random x and y components
Vector2 randomVector2() => (Vector2.random() - Vector2.random()) * 20;
