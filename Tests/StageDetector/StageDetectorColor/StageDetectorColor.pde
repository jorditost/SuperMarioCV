import gab.opencv.*;
import java.awt.Rectangle;
import processing.video.*;

Capture video;
StageDetector stage;
ArrayList<StageElement> stageElements;

Boolean realtimeUpdate = true;

void setup() {
  
  //stage = new StageDetector(this, "after4.jpg");
  stage = new StageDetector(this, 640, 480, KINECT);
  //stage.setSource(KINECT);
  //stage.setMethod(COLOR_FILTER);
  //stage.setMethod(EDGES);
  stage.setMethod(HYBRID);
  //stage.setEdgesThreshold(70);
  
  size(stage.width, stage.height);
  frameRate(30);
  
  stageElements = stage.detect();
}

void draw() {
  
  if ((stage.method != IMAGE_DIFF) && realtimeUpdate) {
    stage.detect();
  }
  
  stage.display();
  //stage.displayBackground();
  stage.displayStageElements();
}

void keyPressed() { 
  /*if (key == ENTER) {
    println(">>>>> DETECT!");
    stageElements = stage.detect();
  }*/
  
  if (key == ENTER) {
    stage.initBackground();
    if (stage.method == EDGES) {
      stage.detect();
    }
    
  } else if (key == ' ') {
    
    if (stage.method == IMAGE_DIFF) {
      stage.initStage();
      stage.detect();
    }
  }
}
