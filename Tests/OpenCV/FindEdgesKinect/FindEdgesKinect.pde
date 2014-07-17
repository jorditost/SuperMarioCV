import gab.opencv.*;
import java.awt.Rectangle;
import SimpleOpenNI.*;

OpenCV opencv;
SimpleOpenNI kinect;
PImage src, processedImage, cannyImage, contoursImage;
ArrayList<Contour> contours;

void setup() {
  frameRate(30);
  
  kinect = new SimpleOpenNI(this);
  kinect.enableRGB();
  
  opencv = new OpenCV(this, 640, 480);
  size(opencv.width, opencv.height, P2D);
  contours = new ArrayList<Contour>();
}

void draw() {
  
  kinect.update();

  // Load the new frame of our movie in to OpenCV
  opencv.loadImage(kinect.rgbImage());
  src = opencv.getSnapshot();
  
  // <1> Pre-process image
  
  // Tell OpenCV to work in HSV color space.
  opencv.useColor(HSB);
  
  // Copy the Saturation channel of our image into 
  // the gray channel, which we process.
  opencv.setGray(opencv.getS().clone());
  
  // Filter the image based on threshold
  opencv.threshold(95);
  
  // Reduce noise
  opencv.erode();
  //opencv.invert();
  
  // Save snapshot of the processed image
  processedImage = opencv.getSnapshot();
  
  // <2> Find Contours in our range image.
  //     Passing 'true' sorts them by descending area.
  contours = opencv.findContours(true,true);
  contoursImage = opencv.getSnapshot();
  
  // <3> Find Edges
  opencv.loadImage(src);
  //opencv.useColor(RGB);
  opencv.findCannyEdges(20,75);
  
  // Dilate and erode to close holes
  opencv.dilate();
  opencv.erode();
  
  cannyImage = opencv.getSnapshot();
  
  displayImages();
}

void displayImages() {
  
  pushMatrix();
  scale(0.5);
  image(src, 0, 0);
  image(processedImage, width, 0);
  image(cannyImage, 0, height);
  image(src, width, height);
  popMatrix();

  displayContours();
}

void displayContours() {
  
  pushMatrix();
  scale(0.5);
  translate(width, height);
  
  noFill();
  strokeWeight(3);
  
  for (int i=0; i<contours.size(); i++) {
    
    Contour contour = contours.get(i);
    Rectangle r = contour.getBoundingBox();
    
    if (//(contour.area() > 0.9 * src.width * src.height) ||
        (r.width < 30 || r.height < 30))
      continue;
    
    stroke(255, 0, 0);
    fill(255, 0, 0, 150);
    strokeWeight(2);
    rect(r.x, r.y, r.width, r.height);
  }
  popMatrix();
}
