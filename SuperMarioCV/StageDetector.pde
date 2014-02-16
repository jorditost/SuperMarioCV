/**
 * StageDetector Class
 * Uses the OpenCV for Processing library by Greg Borenstein
 * https://github.com/atduskgreg/opencv-processing
 * 
 * @Author: Jordi Tost
 * @Author URI: jorditost.com
 *
 * University of Applied Sciences Potsdam, 2013-2014
 */
 
import gab.opencv.*;
import SimpleOpenNI.*;
import java.awt.Rectangle;
import processing.video.*;

// Video Source
static int IMAGE_SRC            = 1;
static int CAPTURE              = 2;
static int KINECT               = 3;

// Detection method
static int EDGES                = 1;
static int IMAGE_DIFF           = 2;
static int COLOR_FILTER         = 3;
static int HYBRID               = 4;

int redH = 167; //3; //167;
int greenH = 105; //37; //44;
int blueH = 0; //119; //104;
int rangeWidth = 5;

class StageDetector {
  
  PApplet parent;
  
  OpenCV opencv;
  SimpleOpenNI kinect;
  Capture video;
  
  int source = CAPTURE;
  int method = EDGES;
  
  // Public vars
  public int width, height;
  public Boolean backgroundInitialized = false;
  public Boolean stageInitialized = false;
  
  // Private vars
  private PImage background, stage;
  private ArrayList<Contour> contours;
  private ArrayList<StageElement> stageElements;
  
  private int edgesThreshold     = 95; // 40: Natural light
  private int imageDiffThreshold = 80;
  
  
  //////////////////
  // Constructors
  //////////////////
  
  StageDetector(PApplet theParent, int requestWidth, int requestHeight, int theSource) {
    
    parent = theParent;
    
    width = requestWidth;
    height = requestHeight;
    
    opencv = new OpenCV(parent, width, height);
    
    source = theSource;
    
    if (source == CAPTURE) {
      video = new Capture(parent, width, height);
      video.start();
    } else if (source == KINECT) {
      kinect = new SimpleOpenNI(parent);
      kinect.enableRGB();
    }
    
    opencv.useColor(HSB);
    
    contours = new ArrayList<Contour>();
    stageElements = new ArrayList<StageElement>();
  }
  
  StageDetector(PApplet theParent, String imageSrc) {
    
    parent = theParent;
    
    source = IMAGE_SRC;
    
    background = loadImage(imageSrc);
   
    width = background.width;
    height = background.height;
    
    opencv = new OpenCV(parent, background);
    opencv.useColor(HSB);
    
    contours = new ArrayList<Contour>();
    stageElements = new ArrayList<StageElement>();
  }
  
  
  /////////////////
  // Set Methods
  /////////////////
  
  void setSource(int theSource) {
    source = theSource;
    
    opencv = new OpenCV(parent, width, height);
    
    if (source == CAPTURE) {
      video = new Capture(parent, width, height);
      video.start();
    } else if (source == KINECT) {
      kinect = new SimpleOpenNI(parent);
      kinect.enableRGB();
    }
  }
  
  void setMethod(int theMethod) {
    method = theMethod;
  }
  
  void setEdgesThreshold(int value) {
    edgesThreshold = value;
    if (method != EDGES) {
      println("You're assigning a threshold for a wrong detection method!");
    }
  }
  
  void setImageDiffThreshold(int value) {
    edgesThreshold = value;
    if (method != IMAGE_DIFF) {
      println("You're assigning a threshold for a wrong detection method!");
    }  
  }
  
  
  ////////////////////
  // Detect Methods
  ////////////////////
  
  public ArrayList<StageElement> detectImageDiff() {
    
    // Image Difference (we need 2 images)
    if (method != IMAGE_DIFF) {
      return null;
    }
       
    if (backgroundInitialized) {
      pushMatrix();
      scale(0.5);
      image(background, 0, 0);
      popMatrix();
  
      if (stageInitialized) {
    
        // Diff
        opencv.loadImage(background);
        opencv.diff(stage);
    
        // Calculate Threshold
        opencv.threshold(imageDiffThreshold);
        
        // Reduce noise
        opencv.erode();
        //opencv.invert();
    
        // Contours
        contours = opencv.findContours(true, true);
  
        // Get stage elements from contours
        stageElements.addAll(getStageElements(contours, NONE));
      }
    }
    
    return stageElements;
  }
  // Returns an array with bounding boxes
  public ArrayList<StageElement> detect() {
    
    contours.clear();
    stageElements.clear();
    
    if (method == IMAGE_DIFF) {
      return detectImageDiff();
    } 
    
    // Update video sour
    updateVideoSource();
    
    // Edge Detection
    if (method == EDGES || method == HYBRID) {
      
      opencv.useColor(HSB);
      opencv.setGray(opencv.getS().clone());
      opencv.threshold(edgesThreshold);
      opencv.erode();
      //opencv.invert();
      
      contours = opencv.findContours(true, true);
    
      // Get stage elements from contours
      stageElements.addAll(getStageElements(contours, NONE));
    } 
    
    // Color filtering
    if (method == COLOR_FILTER || method == HYBRID) {
      
      // Get RED Contours
      ArrayList<Contour> redContours = filterContoursByColor(redH);
      contours.addAll(redContours);
      ArrayList<StageElement> redStageElements = getStageElements(redContours, RED); 
      
      // Get GREEN Contours
      ArrayList<Contour> greenContours = filterContoursByColor(greenH);
      contours.addAll(greenContours);
      ArrayList<StageElement> greenStageElements = getStageElements(greenContours, GREEN);
      
      // Get BLUE Contours
      ArrayList<Contour> blueContours = filterContoursByColor(blueH);
      contours.addAll(blueContours);
      ArrayList<StageElement> blueStageElements = getStageElements(blueContours, BLUE);
      
      // Check repeated elements before adding them
      if (method == HYBRID) {
        checkAddedElements(redStageElements, RED);
        checkAddedElements(greenStageElements, GREEN);
        checkAddedElements(blueStageElements, BLUE);
      } else {
        stageElements.addAll(redStageElements);
        stageElements.addAll(greenStageElements);
        stageElements.addAll(blueStageElements);
      }
    }
    
    //println("Found " + stageElements.size() + " stage elements");
    
    return stageElements;
  }
  
  void checkAddedElements(ArrayList<StageElement> newStageElements, int type) {
    
    for (StageElement newStageElement : newStageElements) {
      
      boolean isAdded = false;
      for (int i=0; i < stageElements.size(); i++) {
        StageElement stageElement = stageElements.get(i);
        
        // Check if they are the same
        if (stageElementsAreTheSame(stageElement, newStageElement)) {
          stageElement.type = type;
          isAdded = true;
          break;
        }
      }
      
      // If it wasn't added, add new
      if (!isAdded) {
          stageElements.add(newStageElement);
      }
    }
  }
  
  boolean stageElementsAreTheSame(StageElement s1, StageElement s2) {
    
    return (abs(s1.rect.x - s2.rect.x) < 8 && 
            abs(s1.rect.y - s2.rect.y) < 8 && 
            abs(s1.rect.width - s2.rect.width) < 8 && 
            abs(s1.rect.height - s2.rect.height) < 8);
  }
  
  // Filter by color
  ArrayList<Contour> filterContoursByColor(int hueValue) {
    
    // background updated in updateVideoSource
    //opencv.loadImage(background);
    
    opencv.useColor(HSB);
    opencv.setGray(opencv.getH().clone());
    opencv.inRange(hueValue-rangeWidth/2, hueValue+rangeWidth/2);
    //opencv.dilate();
    opencv.erode();
    
    //image(opencv.getOutput(), 3*width/4, 3*height/4, width/4, height/4);
    
    return opencv.findContours(true,true);
  }
  
  // Function that filters stage elements from a given countours array
  // Returns cloned array for perform manipulation outside
  private ArrayList<StageElement> getStageElements(ArrayList<Contour> contoursArray, int type) {
    
    ArrayList<StageElement> tempStageElements = new ArrayList<StageElement>();
    //ArrayList<StageElement> clonedStageElements = new ArrayList<StageElement>();
    
    for (Contour contour : contoursArray) {
      /*noFill();
      stroke(0, 255, 0);
      strokeWeight(3);
      contour.draw();*/
      
      Rectangle r = contour.getBoundingBox();
      
      if (r.width < 20 && r.height < 20)
        continue;
      
      StageElement stageElement = new StageElement(r, type);
      tempStageElements.add(stageElement);
      //clonedStageElements.add((StageElement)(stageElement.clone()));
    }
    
    return tempStageElements;
  }
  
  
  ////////////////////////////
  // VIDEO SOURCE Functions
  ////////////////////////////  
  
  // Recalculate Background & Stage key images
  
  // When a key is pressed, capture the background image into the backgroundPixels
  // buffer, by copying each of the current frame's pixels into it.
  public void initBackground() {
    println("Background Initialized");
    
    updateVideoSource();
    
    // Reset stage
    stage = null;
    
    backgroundInitialized = true;
  }
  
  public void initStage() {
    println("Stage Initialized");
    updateVideoSource();
    stageInitialized = true;
  }
  
  void updateVideoSource() {
    
    // CAPTURE
    if (source == CAPTURE && video != null) {
      if (video.available()) {
        video.read();
      }
      opencv.loadImage(video);
      opencv.useColor(HSB);
      background = opencv.getSnapshot();
    
    // KINECT
    } else if (source == KINECT && kinect != null) {
      kinect.update();
      opencv.loadImage(kinect.rgbImage());
      opencv.useColor(HSB);
      background = opencv.getSnapshot();
    }
  }
  
  
  ///////////////////////
  // Display Functions
  ///////////////////////
  
  public void display() {
    
    if (source == CAPTURE) {
     
      if (video.available()) {
        video.read(); 
      }
      
      image(video, 0, 0);
      
    } else if (source == KINECT) {
      
      kinect.update();
      image(kinect.rgbImage(), 0, 0);
      
    } else if (source == IMAGE_SRC) {
      image(background, 0, 0);
    }
  }
  
  public void displayBackground() {
    if (stage != null) {
      image(stage, 0, 0);
    } else if (background != null) {
      image(background, 0, 0);
    }
  }
  
  void displayStageElements() {
    
    //if (contours == null || contours.size() == 0)
    if (contours.size() == 0)
      return;
    
    noFill();
    strokeWeight(3);
    
    // Contours
    /*for (Contour contour : contours) {
      noFill();
      stroke(0, 255, 0);
      strokeWeight(3);
      contour.draw();
    }*/
    
    // Detected stage elements
    for (StageElement stageElement : stageElements) {  
      
      if (stageElement.type == RED) {
        stroke(255, 0, 0);
        fill(255, 0, 0, 150);
      } else if (stageElement.type == GREEN) {
        stroke(0, 255, 0);
        fill(0, 255, 0, 100);
      } else if (stageElement.type == BLUE) {
        stroke(0, 0, 255);
        fill(0, 0, 255, 100);
      } else {
        stroke(0);
        fill(0, 60);
      }
        
      strokeWeight(2);
      rect(stageElement.rect.x, stageElement.rect.y, stageElement.rect.width, stageElement.rect.height);
    }
  }
}
