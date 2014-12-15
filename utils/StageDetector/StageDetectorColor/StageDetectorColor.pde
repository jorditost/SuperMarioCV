/**
 * StageDetectorColor
 * Test sketch for the StageDetector class
 * Check also ImageFilteringWithBlobPersistence.pde for controlling filter values
 *
 * @Author: Jordi Tost @jorditost
 * @Author URI: jorditost.com
 *
 * University of Applied Sciences Potsdam, 2014
 */
 
import gab.opencv.*;
import java.awt.Rectangle;
import SimpleOpenNI.*;
import processing.video.*;

// Source vars
PImage image;
Capture video;
SimpleOpenNI kinect;

static int IMAGE_SRC = 0;
static int CAPTURE   = 1;
static int KINECT    = 2;
int source = KINECT;

// Detector vars
StageDetector stage;
ArrayList<StageElement> stageElements;

Boolean realtimeUpdate = true;

void setup() {
  
  frameRate(30);
  
  // IMAGE_SRC
  if (source == IMAGE_SRC) {
    image = loadImage("data/after4.jpg");
    stage = new StageDetector(this, image.width, image.height);
  
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
  
  // Configure detector
  //stage.setChannel(GRAY);
  //stage.setContrast(1.5);
  stage.setThreshold(75);
  
  // List all filter values
  stage.listFilterValues();
  
  size(stage.width, stage.height);
}

void draw() {
  
  if (realtimeUpdate) {
    detectStage();
  }
  
  stage.displayBackground();
  stage.displayStageElements();
  stage.displayOutputImage();
}

void detectStage() {
  
  // IMAGE
  if (source == IMAGE_SRC) {
    stage.detect(image);
  
  // CAPTURE
  } else if (source == CAPTURE && video != null) {
    if (video.available()) {
      video.read();
    }
    stage.detect(video);
  
  // KINECT
  } else if (source == KINECT && kinect != null) {
    kinect.update();
    stage.detect(kinect.rgbImage());
  }
}

// This is now useless since stage is detected in real-time
void keyPressed() { 
  
  // Use enter to detect stage
  if (key == ENTER) {
    detectStage();
  }
}
