import gab.opencv.*;
import java.awt.Rectangle;

OpenCV opencv;
PImage src, processedImage, cannyImage, contoursImage;
ArrayList<Contour> contours;

void setup() {
  src = loadImage("test.jpg");
  size(src.width, src.height, P2D);
  
  opencv = new OpenCV(this, src);
  opencv.useColor(HSB);
  opencv.setGray(opencv.getS().clone());
  opencv.threshold(95);
  opencv.erode();
  opencv.invert();
  processedImage = opencv.getSnapshot();
  
  // Contours
  //opencv.loadImage(src);
  //opencv.gray();
  //opencv.threshold(92);
  contours = opencv.findContours(true, true);
  contoursImage = opencv.getSnapshot();
  
  // Canny Edges
  opencv.loadImage(src);
  opencv.useColor(RGB);
  opencv.findCannyEdges(20,75);
  opencv.dilate();
  opencv.erode();
  cannyImage = opencv.getSnapshot();
  
  displayImages();
}


void displayImages() {
  pushMatrix();
  scale(0.5);
  image(src, 0, 0);
  image(processedImage, src.width, 0);
  image(cannyImage, 0, src.height);
  image(src, src.width, src.height);
  popMatrix();

  text("Source", 10, 25); 
  text("Pre-processed Image", src.width/2 + 10, 25); 
  text("Canny Edges", 10, src.height/2 + 25); 
  text("Contours", src.width/2 + 10, src.height/2 + 25);
  
  displayContours();
}

void displayContours() {
  
  pushMatrix();
  scale(0.5);
  translate(src.width, src.height);
  
  noFill();
  strokeWeight(3);
  
  for (Contour contour : contours) {
    
    Rectangle r = contour.getBoundingBox();
    
    if ((contour.area() > 0.9 * src.width * src.height) ||
        (r.width < 30 || r.height < 30))
      continue;
    
    stroke(255, 0, 0);
    fill(255, 0, 0, 150);
    strokeWeight(2);
    rect(r.x, r.y, r.width, r.height);
  }
  popMatrix();
}

/*Boolean isContourInsideOther(Rectangle boundingBox) {
  return false;
}

Boolean hitTest(Rectangle a, Rectangle b) {
  
  Boolean xhit, yhit;
  
  if ((a.x > b.x && a.x < b.x + b.width) || (b.x > a.x && b.x < a.x + a.width)) {
    xhit = true;
  } else {
    xhit = false;
  }
  
  if ((a.y > b.x && a.x < b.x + b.height) || (b.y > a.y && b.y < a.y + a.height)) {
    yhit = true;
  } else {
    yhit = false;
  }
  
  if (xhit && yhit) {
    return true;
  } else {
    return false;
  }
}*/
