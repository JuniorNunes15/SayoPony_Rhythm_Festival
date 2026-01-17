class Note {
  int lane;
  float x;
  float hitTime;
  float endTime;
  boolean isHold;
  boolean hit = false;
  boolean isHolding = false;
  boolean ended = false;
  
  float speed; 
  float travelTime; 
  float spawnY;
  
  float size = 36*2;
  
  Note(int lane_, float x_, float hitTime_, float speed_, float travelTime_, float spawnY_, float endTime_) {
    lane = lane_;
    x = x_;
    hitTime = hitTime_;
    speed = speed_;
    travelTime = travelTime_;
    spawnY = spawnY_;
    if (endTime_ > hitTime_) {
      endTime = endTime_;
      isHold = true;
    } else {
      endTime = -1;
      isHold = false;
    }
  }
  
  void update(float now) {
    if (isHold && !hit) {
      }
    }
  
    float currentY(float now) {
    float t0 = hitTime - travelTime;   
    float t1 = hitTime; 
    float y;
  
    if (now <= t0) {
      y = spawnY;
    } 
    else if (now < t1) {
      float p = (now - t0) / (t1 - t0);
      y = lerp(spawnY, hitLineY, p);
    } 
    else {
      float extraTime = now - t1;
      y = hitLineY + extraTime * speed;
    }
    return y;
  }
  
  void draw(float now) {
    if (hit) return;
  
    float y = currentY(now);
  
    pushMatrix();
    translate(x, y);
    imageMode(CENTER);
    image(noteImgs[lane], 0, 0, size, size);
  
    if (isHold) {
      float holdHeight = (endTime > now)
        ? max(10, (endTime - now) / travelTime * travelDistance)
        : 10;
      fill(120, 180, 255, 160);
      rectMode(CENTER);
      rect(0, holdHeight / 2, 40, holdHeight);
      image(noteImgs[lane], 0, 0, size, size);
    } 
    else {
      image(noteImgs[lane], 0, 0, size, size);
    }
    popMatrix();
  }
}
