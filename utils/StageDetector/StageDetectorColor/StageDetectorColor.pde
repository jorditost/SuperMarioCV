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

PImage image;
Capture video;
SimpleOpenNI kinect;
StageDetector stage;
ArrayList<StageElement> stageElements;

// Image source
static int IMAGE_SRC = 0;
static int CAPTURE   = 1;
static int KINECT    = 2;
int source = KINECT;

Boolean realtimeUpdate = true;

void setup() {
  
  frameRate(30);
  
  // IMAGE_SRC
  if (source == IMAGE_SRC) {
    image = loadImage("after4.jpg");
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
