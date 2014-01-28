import SimpleOpenNI.*;
import gab.opencv.*;

PImage src;
OpenCV opencv;

int roiWidth = 150;
int roiHeight = 150;

SimpleOpenNI kinect;

boolean useROI = true;

void setup() {
  
  opencv = new OpenCV(this, 640, 480);
  
  kinect = new SimpleOpenNI(this);
  kinect.enableRGB();
  
  size(opencv.width, opencv.height, P2D);
}

void draw() {
  
  kinect.update();
  opencv.loadImage(kinect.rgbImage());

  if (useROI) {
    opencv.setROI(mouseX, mouseY, roiWidth, roiHeight);
  }

  opencv.findCannyEdges(20,75);
  image(opencv.getOutput(), 0, 0);
}

// toggle ROI on and off
void keyPressed() {
  useROI = !useROI;

  if (!useROI) {
    opencv.releaseROI();
  }
}

