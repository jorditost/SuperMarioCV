import gab.opencv.*;
import SimpleOpenNI.*;
import java.awt.Rectangle;
import processing.video.*;

static int STATIC  = 1;
static int CAPTURE = 2;
static int KINECT  = 3;

class StageDetector {
  
  PApplet parent;
  
  OpenCV opencv;
  SimpleOpenNI kinect;
  Capture video;
  
  int source;
  
  private PImage background;
  private ArrayList<Contour> contours;
  private ArrayList<Rectangle> stageElements;
  public int width, height;
  
  StageDetector(PApplet theParent, int requestWidth, int requestHeight, int theSource) {
    
    parent = theParent;
    source = theSource;
     
    width = requestWidth;
    height = requestHeight;
    
    opencv = new OpenCV(parent, width, height);
    
    if (source == CAPTURE) {
      video = new Capture(parent, width, height);
      video.start();
    } else if (source == KINECT) {
      kinect = new SimpleOpenNI(parent);
      kinect.enableRGB();
    }
  }
  
  StageDetector(PApplet theParent, String imageSrc) {
    
    parent = theParent;
    
    background = loadImage(imageSrc);
   
    width = background.width;
    height = background.height;
    
    opencv = new OpenCV(parent, background);
    //opencv = new OpenCV(parent, width, height);
    
    source = STATIC;
  }
  
  // Detect stage elements
  // Returns an array with bounding boxes
  public ArrayList<Rectangle> detect() {
    
    if (source == CAPTURE && video.available()) {
      video.read();
      //opencv.useColor();
      opencv.loadImage(video);
      background = opencv.getSnapshot();
    
    } else if (source == KINECT && kinect != null) {
      kinect.update();
      opencv.loadImage(kinect.rgbImage());
      background = opencv.getSnapshot();
    }
    
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
