// https://github.com/atduskgreg/opencv-processing-book/blob/master/book/tracking/background_subtraction.md

import gab.opencv.*;
import processing.video.*;

Capture video;
OpenCV opencv;

void setup() {
  video = new Capture(this, 640, 480);
  opencv = new OpenCV(this, video.width, video.height);
  size(video.width, video.height, P2D);
  
  opencv.startBackgroundSubtraction(0, 3, 0.5);
  
  video.start();
}

void draw() {
  image(video, 0, 0);  
  opencv.loadImage(video);
  opencv.updateBackground();
  
  opencv.dilate();
  opencv.erode();
  
  noFill();
  stroke(255, 0, 0);
  strokeWeight(3);
  for (Contour contour : opencv.findContours()) {
    contour.draw();
  }
}

void captureEvent(Capture m) {
  m.read();
}
