import gab.opencv.*;
import java.awt.Rectangle;
import processing.video.*;

Capture video;
StageDetector stage;
ArrayList<Rectangle> stageElements;

void setup() {
  
  //stage = new StageDetector(this, "after4.jpg");
  stage = new StageDetector(this, 640, 480, CAPTURE);
  //stage = new StageDetector(this, 640, 480, KINECT);
 
  size(stage.width, stage.height);
  frameRate(30);
  
  stageElements = stage.detect();
}

void draw() {
  stage.displayBackground();
  stage.displayContours();
  
  /*for (Rectangle r : stageElements) {  
    stroke(255, 0, 0);
    fill(255, 0, 0, 150);
    strokeWeight(2);
    rect(r.x, r.y, r.width, r.height);
  }*/
}

void keyPressed() { 
  if (key == ENTER) {
    println(">>>>> DETECT!");
    stageElements = stage.detect();
  }
}
