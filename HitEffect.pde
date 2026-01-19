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
    float p = t / life;
  
    pushMatrix();
    translate(x, y);
    imageMode(CENTER);
  
    float scale = 1.0 + p * 0.6;
    float alpha = (1 - p) * 255;
  
    tint(255, alpha);
  
    if (type.equals("perfect")) {
      image(hitPerfect, 0, 0, 120 * scale, 120 * scale);
      fill(255);
      text("PERFECT", 0, -40 - p * 30);
  
    } else if (type.equals("good")) {
      image(hitGood, 0, 0, 110 * scale, 110 * scale);
      fill(255);
      text("GOOD", 0, -32 - p * 24);
  
    } else {
      image(hitMiss, 0, 0, 100 * scale, 100 * scale);
      fill(255);
      text("MISS", 0, -28 - p * 20);
    }
  
    noTint();
    popMatrix();
  }

}
