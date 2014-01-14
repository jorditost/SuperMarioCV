import gab.opencv.*;
import java.awt.Rectangle;
import processing.video.*;

Capture video;
StageDetector stage;
ArrayList<Rectangle> stageElements;

void setup() {
  
  //stage = new StageDetector(this, "after4.jpg");
  stage = new StageDetector(this, 640, 480);
  stage.setSource(CAPTURE);
  //stage.setMethod(IMAGE_DIFF);
  stage.setMethod(EDGES);
  
  //stage = new StageDetector(this, 640, 480, KINECT);
 
  size(stage.width, stage.height);
  frameRate(30);
  
  stageElements = stage.detect();
}

void draw() {
  stage.displayBackground();
  stage.displayContours();
}

void keyPressed() { 
  /*if (key == ENTER) {
    println(">>>>> DETECT!");
    stageElements = stage.detect();
  }*/
  
  if (key == ENTER) {
    stage.initBackground();
  } else if (key == ' ') {
    stage.initStage();
    stage.detect();
  }
}
