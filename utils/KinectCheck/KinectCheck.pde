/**
 * KinectCheck
 *
 * Modified by Jordi Tost @jorditost
 */
 
import SimpleOpenNI.*;
import java.awt.Rectangle;

SimpleOpenNI kinect;

void setup() {
  
  kinect = new SimpleOpenNI(this);
  kinect.enableRGB();
  size(640,480);
}

void draw() {
  
  kinect.update();
  image(kinect.rgbImage(), 0, 0);
}
