import 'package:flutter/painting.dart';
import 'package:liquid_simulation/main.dart';

class Fluid {
  static const int iter = 8;

  final double scale;
  final int size;

  final double dt;
  final double diff;
  final double visc;

  late List<double> s;
  late List<double> density;

  late List<double> Vx;
  late List<double> Vy;

  late List<double> Vx0;
  late List<double> Vy0;

  Fluid(this.dt, this.diff, this.visc, this.scale, this.size) {
    s = List.filled(size * size, 0);
    density = List.filled(size * size, 0);

    Vx = List.filled(size * size, 0);
    Vy = List.filled(size * size, 0);

    Vx0 = List.filled(size * size, 0);
    Vy0 = List.filled(size * size, 0);
  }

  void step() {
    double visc = this.visc;
    double diff = this.diff;
    double dt = this.dt;
    List<double> Vx = this.Vx;
    List<double> Vy = this.Vy;
    List<double> Vx0 = this.Vx0;
    List<double> Vy0 = this.Vy0;
    List<double> s = this.s;
    List<double> density = this.density;

    diffuse(1, Vx0, Vx, visc, dt);
    diffuse(2, Vy0, Vy, visc, dt);

    project(Vx0, Vy0, Vx, Vy);

    advect(1, Vx, Vx0, Vx0, Vy0, dt);
    advect(2, Vy, Vy0, Vx0, Vy0, dt);

    project(Vx, Vy, Vx0, Vy0);

    diffuse(0, s, density, diff, dt);
    advect(0, density, s, Vx, Vy, dt);
  }

  void addDensity(int x, int y, double amount) {
    int index = IX(x, y);
    this.density[index] += amount;
  }

  void addVelocity(int x, int y, double amountX, double amountY) {
    int index = IX(x, y);
    this.Vx[index] += amountX;
    this.Vy[index] += amountY;
  }

  void renderD(Canvas c) {
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        double x = (i * scale).toDouble();
        double y = (j * scale).toDouble();
        double d = this.density[IX(i, j)];
        double density = d.map(0, 255, 0, 1).clamp(0, 1);

        final rect = Rect.fromCircle(
          center: Offset(x, y),
          radius: scale.toDouble(),
        );

        final color = ((d + 50) % 255).floor();
        final paint = Paint()..color = Color.fromRGBO(color, color, color, density);

      

        c.drawRect(rect, paint);
      }
    }
  }

  void fadeD() {
    for (int i = 0; i < this.density.length; i++) {
      double d = density[i];
      density[i] = (d - 0.005).clamp(0, 255);
    }
  }

  int IX(int x, int y) {
    x = x.clamp(0, size - 1);
    y = y.clamp(0, size - 1);
    return x + (y * size);
  }

  void diffuse(int b, List<double> x, List<double> x0, double diff, double dt) {
    final a = dt * diff * (size - 2) * (size - 2);
    lin_solve(b, x, x0, a, 1 + 4 * a);
  }

  void lin_solve(int b, List<double> x, List<double> x0, double a, double c) {
    final cRecip = 1.0 / c;
    for (int k = 0; k < iter; k++) {
      for (int j = 1; j < size - 1; j++) {
        for (int i = 1; i < size - 1; i++) {
          x[IX(i, j)] = (x0[IX(i, j)] +
                  a *
                      (x[IX(i + 1, j)] +
                          x[IX(i - 1, j)] +
                          x[IX(i, j + 1)] +
                          x[IX(i, j - 1)])) *
              cRecip;
        }
      }

      set_bnd(b, x);
    }
  }

  void project(List<double> velocX, List<double> velocY, List<double> p,
      List<double> div) {
    for (int j = 1; j < size - 1; j++) {
      for (int i = 1; i < size - 1; i++) {
        div[IX(i, j)] = -0.5 *
            (velocX[IX(i + 1, j)] -
                velocX[IX(i - 1, j)] +
                velocY[IX(i, j + 1)] -
                velocY[IX(i, j - 1)]) /
            size;
        p[IX(i, j)] = 0;
      }
    }

    set_bnd(0, div);
    set_bnd(0, p);
    lin_solve(0, p, div, 1, 4);

    for (int j = 1; j < size - 1; j++) {
      for (int i = 1; i < size - 1; i++) {
        velocX[IX(i, j)] -= 0.5 * (p[IX(i + 1, j)] - p[IX(i - 1, j)]) * size;
        velocY[IX(i, j)] -= 0.5 * (p[IX(i, j + 1)] - p[IX(i, j - 1)]) * size;
      }
    }
    set_bnd(1, velocX);
    set_bnd(2, velocY);
  }

  void advect(int b, List<double> d, List<double> d0, List<double> velocX,
      List<double> velocY, double dt) {
    double i0, i1, j0, j1;

    double dtx = dt * (size - 2);
    double dty = dt * (size - 2);

    double s0, s1, t0, t1;
    double tmp1, tmp2, x, y;

    double Nfloat = size.toDouble();

    for (int j = 1, jfloat = 1; j < size - 1; j++, jfloat++) {
      for (int i = 1, ifloat = 1; i < size - 1; i++, ifloat++) {
        tmp1 = dtx * velocX[IX(i, j)];
        tmp2 = dty * velocY[IX(i, j)];
        x = ifloat - tmp1;
        y = jfloat - tmp2;

        if (x < 0.5) x = 0.5;
        if (x > Nfloat + 0.5) x = Nfloat + 0.5;
        i0 = x.floorToDouble();
        i1 = i0 + 1.0;
        if (y < 0.5) y = 0.5;
        if (y > Nfloat + 0.5) y = Nfloat + 0.5;
        j0 = y.floorToDouble();
        j1 = j0 + 1.0;

        s1 = x - i0;
        s0 = 1.0 - s1;
        t1 = y - j0;
        t0 = 1.0 - t1;

        int i0i = i0.toInt();
        int i1i = i1.toInt();
        int j0i = j0.toInt();
        int j1i = j1.toInt();

        d[IX(i, j)] = s0 * (t0 * d0[IX(i0i, j0i)] + t1 * d0[IX(i0i, j1i)]) +
            s1 * (t0 * d0[IX(i1i, j0i)] + t1 * d0[IX(i1i, j1i)]);
      }
    }

    set_bnd(b, d);
  }

  void set_bnd(int b, List<double> x) {
    for (int i = 1; i < size - 1; i++) {
      x[IX(i, 0)] = b == 2 ? -x[IX(i, 1)] : x[IX(i, 1)];
      x[IX(i, size - 1)] = b == 2 ? -x[IX(i, size - 2)] : x[IX(i, size - 2)];
    }
    for (int j = 1; j < size - 1; j++) {
      x[IX(0, j)] = b == 1 ? -x[IX(1, j)] : x[IX(1, j)];
      x[IX(size - 1, j)] = b == 1 ? -x[IX(size - 2, j)] : x[IX(size - 2, j)];
    }

    x[IX(0, 0)] = 0.5 * (x[IX(1, 0)] + x[IX(0, 1)]);
    x[IX(0, size - 1)] = 0.5 * (x[IX(1, size - 1)] + x[IX(0, size - 2)]);
    x[IX(size - 1, 0)] = 0.5 * (x[IX(size - 2, 0)] + x[IX(size - 1, 1)]);
    x[IX(size - 1, size - 1)] =
        0.5 * (x[IX(size - 2, size - 1)] + x[IX(size - 1, size - 2)]);
  }
}
