class HitEffect {
  float x, y;
  String type;
  float life = 0.5;
  float t = 0;

  HitEffect(float x_, float y_, String type_) {
    x = x_; y = y_; type = type_;
  }

  void update() {
    t += 1.0/frameRate;
  }

  boolean isDone() {
    return t > life;
  }

  void draw() {
    float p = t/life;
    pushMatrix();
    translate(x, y);
    noStroke();
    if (type.equals("perfect")) {
      fill(255, 240, 100, (1-p)*255);
      ellipse(0, 0, 40 + p*60, 40 + p*60);
      fill(255);
      text("PERFECT", 0, -30 - p*30);
    } else if (type.equals("good")) {
      fill(150, 220, 255, (1-p)*255);
      ellipse(0, 0, 36 + p*40, 36 + p*40);
      fill(255);
      text("GOOD", 0, -22 - p*20);
    } else {
      fill(200, 80, 80, (1-p)*255);
      ellipse(0, 0, 30 + p*30, 30 + p*30);
      fill(255);
      text("MISS", 0, -18 - p*18);
    }
    popMatrix();
  }
}
