/**
 * HSVColorTrackingImage
 * Greg Borenstein
 * https://github.com/atduskgreg/opencv-processing-book/blob/master/code/hsv_color_tracking/HSVColorTracking/HSVColorTracking.pde
 *
 * Modified by Jordi Tost @jorditost (color selection + image source)
 */
 
import gab.opencv.*;
import processing.video.*;
import java.awt.Rectangle;

PImage img;
OpenCV opencv;
ArrayList<Contour> contours;

// <1> Set the range of Hue values for our filter
int rangeLow = 150;
int rangeHigh = 160;

void setup() {
  img = loadImage("after4.jpg");
  opencv = new OpenCV(this, img);
  size(opencv.width, opencv.height, P2D);
  opencv.useColor(HSB);
  contours = new ArrayList<Contour>();
}

void draw() {
  opencv.loadImage(img);
  
  image(img, 0, 0);

  // <2> Load the new frame of our movie in to OpenCV
  //opencv.loadImage(video);
  
  // <3> Tell OpenCV to work in HSV color space.
  opencv.useColor(HSB);
  
  // <4> Copy the Hue channel of our image into 
  //     the gray channel, which we process.
  opencv.setGray(opencv.getH().clone());
  
  // <5> Filter the image based on the range of 
  //     hue values that match the object we want to track.
  opencv.inRange(rangeLow, rangeHigh);
  
  //opencv.dilate();
  opencv.erode();
  opencv.erode();
  
  // <6> Display the processed image for reference.
  image(opencv.getOutput(), 3*width/4, 3*height/4, width/4, height/4);
  
  // <7> Find contours in our range image.
  //     Passing 'true' sorts them by descending area.
  contours = opencv.findContours(true,true);
  
  contours = parseContours(contours);
  
  println("num contours: " + contours.size());
  // <8> Check to make sure we've found any contours
  if (contours.size() > 0) {
    
    for (Contour c : contours) {
      // <10> Find the bounding box of the largest contour,
      //      and hence our object.
      Rectangle r = c.getBoundingBox();
    
      // <11> Draw the bounding box of our object
      noFill(); 
      strokeWeight(1); 
      stroke(255, 0, 0);
      rect(r.x, r.y, r.width, r.height);
      // <12> Draw a dot in the middle of the bounding box, on the object.
      noStroke(); 
      fill(255, 0, 0);
      //ellipse(r.x + r.width/2, r.y + r.height/2, 30, 30);
    }
    
    // <9> Get the first contour, which will be the largest one
    Contour biggestContour = contours.get(0);
  
    // <10> Find the bounding box of the largest contour,
    //      and hence our object.
    Rectangle r = biggestContour.getBoundingBox();
  
    // <11> Draw the bounding box of our object
    noFill(); 
    strokeWeight(2); 
    stroke(255, 0, 0);
    rect(r.x, r.y, r.width, r.height);
    // <12> Draw a dot in the middle of the bounding box, on the object.
    noStroke(); 
    fill(255, 0, 0);
    ellipse(r.x + r.width/2, r.y + r.height/2, 30, 30);
  }
}

ArrayList<Contour> parseContours(ArrayList<Contour> contoursArray) {
      
    
    ArrayList<Contour> parsedContours = new ArrayList<Contour>();
      
    for (Contour contour : contoursArray) {
        
      Rectangle r = contour.getBoundingBox();
        
      if (//(float(r.width)/float(displayWidth) > 0.3 || float(r.height)/float(displayWidth) > 0.3) ||
         (r.width > 400 || r.height > 400) ||
         (r.width < 20 && r.height < 20))
        continue;
        
      parsedContours.add(contour);
      }
      
      return parsedContours;
  }

void mousePressed() {
  
  color c = get(mouseX, mouseY);
  println("r: " + red(c) + " g: " + green(c) + " b: " + blue(c));
   
  int hue = int(map(hue(c), 0, 255, 0, 180));
  println("hue to detect: " + hue);
  
  rangeLow = hue - 5;
  rangeHigh = hue + 5;
}
