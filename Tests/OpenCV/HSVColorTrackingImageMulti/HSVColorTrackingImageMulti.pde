import gab.opencv.*;
import processing.video.*;
import java.awt.Rectangle;

PImage img;
OpenCV opencv;
ArrayList<Contour> contours;

// <1> Set the range of Hue values for our filter

int redH = 166;
int greenH = 44;
int blueH = 104;

int rangeWidth = 10;

//int rangeLow = 150;
//int rangeHigh = 160;

void setup() {
  img = loadImage("after4.jpg");
  opencv = new OpenCV(this, img);
  size(opencv.width, opencv.height, P2D);
  opencv.useColor(HSB);
  contours = new ArrayList<Contour>();
}

void draw() {
  
  // <2> Load image
  image(img, 0, 0);
  //opencv.loadImage(video);
  
  // Filter RED
  opencv.loadImage(img);
  opencv.useColor(HSB);
  opencv.setGray(opencv.getH().clone());
  opencv.inRange(redH-rangeWidth/2, redH+rangeWidth/2);
  //opencv.dilate();
  opencv.erode();
  
  //image(opencv.getOutput(), 3*width/4, 3*height/4, width/4, height/4);
  
  ArrayList<Contour> redContours = opencv.findContours(true,true);
  contours.addAll(redContours);
  
  // Filter GREEN
//  opencv.loadImage(img);
//  opencv.useColor(HSB);
//  opencv.setGray(opencv.getH().clone());
//  opencv.inRange(greenH-rangeWidth/2, greenH+rangeWidth/2);
//  //opencv.dilate();
//  opencv.erode();
//  
//  //image(opencv.getOutput(), 3*width/4, 3*height/4, width/4, height/4);
//  
//  ArrayList<Contour> greenContours = opencv.findContours(true,true);
//  contours.addAll(greenContours);

  // Filter BLUE
  opencv.loadImage(img);
  opencv.useColor(HSB);
  opencv.setGray(opencv.getH().clone());
  opencv.inRange(blueH-rangeWidth/2, blueH+rangeWidth/2);
  //opencv.dilate();
  opencv.erode();
  
  //image(opencv.getOutput(), 3*width/4, 3*height/4, width/4, height/4);
  
  ArrayList<Contour> blueContours = opencv.findContours(true,true);
  contours.addAll(blueContours);
  
  // We display all contours
  displayContours();
}

void displayContours() {
  
    if (contours == null || contours.size() == 0) 
      return;
      
    noFill();
    strokeWeight(3);
    
    // Detected stage elements
    for (Contour contour : contours) {
      
      Rectangle r = contour.getBoundingBox();
      
      if (r.width < 20 || r.height < 20)
        continue;
      
//      stroke(255, 0, 0);
//      fill(255, 0, 0, 150);
//      strokeWeight(2);
//      rect(r.x, r.y, r.width, r.height);
      
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

/*void mousePressed() {
  
  color c = get(mouseX, mouseY);
  println("r: " + red(c) + " g: " + green(c) + " b: " + blue(c));
   
  int hue = int(map(hue(c), 0, 255, 0, 180));
  println("hue to detect: " + hue);
  
  rangeLow = hue - 5;
  rangeHigh = hue + 5;
}*/
