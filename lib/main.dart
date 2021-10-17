import 'dart:math';

import 'package:flutter/material.dart';
import 'package:funvas/funvas.dart';
import 'package:liquid_simulation/fluid.dart';

void main() {
  runApp(const MyApp());
}

extension NumExtension<T extends num> on num {
  /// maps a number from an old range to a new range
  double map(T oldStart, T oldEnd, T newStart, T newEnd) {
    final slope = (newEnd - newStart) / (oldEnd - oldStart);
    return newStart + slope * (this - oldStart);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final scale = 4.0;
      final size = (constraints.maxHeight / scale).round();

      return SizedBox.expand(
        child: FunvasContainer(
          funvas: LiquidSimulation(scale, size),
        ),
      );
    });
  }
}

class LiquidSimulation extends Funvas {
  LiquidSimulation(this.scale, this.size);

  final double scale;
  final int size;

  late Fluid fluid = Fluid(0.2, 0, 0.0000001, scale, size);

  late double width = size * scale;
  late double height = size * scale;

  @override
  void u(double t) {
    final cx = (0.5 * width / scale).round();
    final cy = (0.5 * height / scale).round();

    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        fluid.addDensity(
          cx + i,
          cy + j,
          (50 + Random().nextInt(100)).toDouble(),
        );
      }
    }
    for (int i = 0; i < 2; i++) {
      fluid.addVelocity(cx, cy, 2, 2);
    }

    fluid.step();
    fluid.renderD(c);
    //fluid.fadeD();
  }
}
