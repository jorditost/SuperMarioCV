import gab.opencv.*;
import java.awt.Rectangle;
import SimpleOpenNI.*;
import processing.video.*;

Capture video;
SimpleOpenNI kinect;
StageDetector stage;
ArrayList<StageElement> stageElements;

static int IMAGE_SRC = 0;
static int CAPTURE   = 1;
static int KINECT    = 2;

int source = CAPTURE;
int method = StageDetector.BLOB_DETECTION; 

Boolean realtimeUpdate = true;

void setup() {
  
  // IMAGE_SRC
  if (source == IMAGE_SRC) {
    stage = new StageDetector(this, "after4.jpg");
  
  // CAPTURE
  } else if (source == CAPTURE) {
    video = new Capture(this, 640, 480);
    video.start();
    stage = new StageDetector(this, 640, 480);
  
  // KINECT
  } else if (source == KINECT) {
    kinect = new SimpleOpenNI(this);
    kinect.enableRGB();
    stage = new StageDetector(this, 640, 480);
  }
  
  stage.setMethod(method);
  
  frameRate(30);
  size(stage.width, stage.height);
  
  //stageElements = stage.detect();
}

void draw() {
  
  if (source != IMAGE_SRC && realtimeUpdate) {
    
    // CAPTURE
    if (source == CAPTURE && video != null) {
      if (video.available()) {
        video.read();
        stage.detect(video);
      }
    
    // KINECT
    } else if (source == KINECT && kinect != null) {
      kinect.update();
      stage.detect(kinect.rgbImage());
    }
  }
  
  stage.displayBackground();
  stage.displayStageElements();
  stage.displayOutputImage();
}

void keyPressed() { 
  
  // Use enter to detect stage
  if (key == ENTER) {
    
    // CAPTURE
    if (source == CAPTURE && video != null) {
      if (video.available()) {
        video.read();
        stage.detect(video);
      }
    
    // KINECT
    } else if (source == KINECT && kinect != null) {
      kinect.update();
      stage.detect(kinect.rgbImage());
    }
  }
}
