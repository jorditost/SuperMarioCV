import gab.opencv.*;
import java.awt.Rectangle;
import processing.video.*;

class StageDetector {
  
  OpenCV opencv;
  Capture video;
  private PImage background;
  private ArrayList<Contour> contours;
  private ArrayList<Rectangle> stageElements;
  public int width, height;
  
  StageDetector(PApplet parent) {
    
    background = loadImage("after4.jpg");
    
    width = background.width;
    height = background.height;
    
    //video = new Capture(parent, requestWidth, requestHeight);
    opencv = new OpenCV(parent, width, height);
    
    //video.start();
  }
  
  // Detect stage elements
  // Returns an array with bounding boxes
  public ArrayList<Rectangle> detect() {
    
    opencv.loadImage(background);
    
    opencv.useColor(HSB);
    opencv.setGray(opencv.getS().clone());
    opencv.threshold(95);
    opencv.erode();
    //opencv.invert();
    
    contours = opencv.findContours(true, true);
    
    // Get stage elements from contours
    return getStageElements(contours);
  }
  
  // Function that filters stage elements from a given countours array
  // Returns cloned array for perform manipulation outside
  private ArrayList<Rectangle> getStageElements(ArrayList<Contour> contoursArray) {
    
    ArrayList<Rectangle> clonedStageElements = new ArrayList<Rectangle>();
    stageElements = new ArrayList<Rectangle>();
    
    for (Contour contour : contoursArray) {
      noFill();
      stroke(0, 255, 0);
      strokeWeight(3);
      contour.draw();
      
      Rectangle r = contour.getBoundingBox();
      
      if (//(contour.area() > 0.9 * src.width * src.height) ||
          (r.width < 30 || r.height < 30))
        continue;
      
      stageElements.add(r);
      clonedStageElements.add((Rectangle)(r.clone()));
    }
    
    return clonedStageElements;
  }
  
  ///////////////////////
  // Display Functions
  ///////////////////////
  
  public void display() {
   
    if (video.available()) {
      video.read(); 
    }
    
    image(video, 0, 0);
  }
  
  public void displayBackground() {
    if (background != null) {
      image(background, 0, 0);
    }
  }
  
  void displayContours() {
  
    noFill();
    strokeWeight(3);
    
    // Contours
    for (Contour contour : contours) {
      noFill();
      stroke(0, 255, 0);
      strokeWeight(3);
      contour.draw();
    }
    
    // Detected stage elements
    for (Rectangle r : stageElements) {  
      stroke(255, 0, 0);
      fill(255, 0, 0, 150);
      strokeWeight(2);
      rect(r.x, r.y, r.width, r.height);
    }
  }
}
