import 'package:flutter/material.dart';
import 'package:funvas/funvas.dart';
import 'package:liquid_simulation/fluid.dart';

void main() => runApp(MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late LiquidSimulation funvas;
  int size = 128;

  @override
  void initState() {
    super.initState();
    funvas = LiquidSimulation(scale: 4.0, size: size);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: GestureDetector(
        onPanStart: (d) => funvas.updateFluidPosition(
          active: true,
          sourcePosition: d.globalPosition,
        ),
        onPanUpdate: (d) => funvas.updateFluidPosition(
          sourcePosition: d.globalPosition,
          velocity: d.delta,
        ),
        onPanEnd: (d) => funvas.updateFluidPosition(
          active: false,
        ),
        child: FunvasContainer(
          funvas: funvas,
        ),
      ),
    );
  }
}

class LiquidSimulation extends Funvas {
  LiquidSimulation({
    required this.scale,
    required this.size,
  });

  final double scale;
  final int size;

  late bool active = false;
  late Offset sourcePosition = Offset.zero;
  late Offset velocity = Offset.zero;

  late Fluid fluid = Fluid(0.2, 0, 0.0000001, scale, size);
  late double width = size * scale;
  late double height = size * scale;

  void updateFluidPosition({
    bool? active,
    Offset? sourcePosition,
    Offset? velocity,
  }) {
    if (active != null) this.active = active;
    if (sourcePosition != null) this.sourcePosition = sourcePosition;
    if (velocity != null) this.velocity = velocity;
  }

  @override
  void u(double t) {
    if (active) {
      final x = (sourcePosition.dx / scale).round();
      final y = (sourcePosition.dy / scale).round();

      fluid.addDensity(x, y, 1000);
      fluid.addVelocity(x, y, velocity.dx, velocity.dy);
    }

    fluid.step();
    fluid.renderD(c);
  }
}
