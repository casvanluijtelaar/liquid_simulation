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
  Offset size = Offset(100, 100);

  @override
  void initState() {
    super.initState();
    funvas = LiquidSimulation(size: size);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    this.size = Offset(size.width, size.height);

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
    required this.size,
  });

  final Offset size;

  late bool active = false;
  late Offset sourcePosition = Offset.zero;
  late Offset velocity = Offset.zero;

  late Fluid fluid = Fluid(0.2, 0, 0.0000001, size.dx.toInt(), size.dy.toInt());

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
      fluid.addDensity(
        sourcePosition.dx.floor(),
        sourcePosition.dy.floor(),
        1000,
      );
      fluid.addVelocity(
        sourcePosition.dx.floor(),
        sourcePosition.dy.floor(),
        velocity.dx,
        velocity.dy,
      );
    }

    fluid.step();
    fluid.renderD(c);
    //fluid.fadeD();
  }
}
