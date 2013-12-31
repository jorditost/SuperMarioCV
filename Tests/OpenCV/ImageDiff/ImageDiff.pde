import gab.opencv.*;
import java.awt.Rectangle;

OpenCV opencv;
PImage  before, after, grayDiff;
PImage thresholdImage;
//PImage colorDiff;
ArrayList<Contour> contours;

void setup() {
  before = loadImage("before4.jpg");
  after = loadImage("after4.jpg");
  size(before.width, before.height);

  opencv = new OpenCV(this, before);    
  opencv.diff(after);
  grayDiff = opencv.getSnapshot(); 
  
  // Calculate Threshold
  opencv.threshold(30);
  //opencv.threshold(80);
  
  // Reduce noise
  //opencv.dilate();
  opencv.erode();
  //opencv.invert();
  thresholdImage = opencv.getSnapshot();
  
  // Contours
  contours = opencv.findContours(true,true);
}

void draw() {
  pushMatrix();
  scale(0.5);
  image(before, 0, 0);
  image(after, before.width, 0);
  image(thresholdImage, 0, before.height);
  image(grayDiff, before.width, before.height);
  
  translate(0, before.height);
  displayContours();
  
  popMatrix();

  fill(255);
  text("before", 10, 20);
  text("after", before.width/2 +10, 20);
  text("gray diff", before.width/2 + 10, before.height/2+ 20);

//  text("color diff", 10, before.height/2+ 20);
}

void displayContours() {
  
  noFill();
  strokeWeight(3);
  
  for (int i=0; i<contours.size(); i++) {
  
    Contour contour = contours.get(i);
    
    noFill();
    stroke(0, 255, 0);
    strokeWeight(3);
    contour.draw();
    
    Rectangle r = contour.getBoundingBox();
    
    if (//(contour.area() > 0.9 * before.width * before.height) ||
        (r.width < 30 || r.height < 30))
      continue;
    
    stroke(255, 0, 0);
    fill(255, 0, 0, 150);
    strokeWeight(2);
    rect(r.x, r.y, r.width, r.height);
  }
}

