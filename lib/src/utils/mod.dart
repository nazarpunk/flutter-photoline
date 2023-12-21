class PhotolineMod {
  PhotolineMod(this.t, this.dt);

  double t;
  double dt;

  set dx(double dx) => t = (t + dx * dt).clamp(0, 1);
}
