/**
 * KinectCheck
 *
 * Modified by Jordi Tost @jorditost
 */
 
import SimpleOpenNI.*;
import java.awt.Rectangle;

SimpleOpenNI kinect;

void setup() {
  frameRate(15);
  kinect = new SimpleOpenNI(this);
  kinect.enableRGB();
  size(640,480);
}

void draw() {
  
  kinect.update();
  image(kinect.rgbImage(), 0, 0);
  
  // Print text if new color expected
  textSize(18);
  stroke(255,0,0);
  fill(255,0,0);
  
  text(frameRate + " fps", 20, 20);
}
