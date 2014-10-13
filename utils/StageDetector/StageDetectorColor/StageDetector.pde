/**
 * StageDetector Class
 * Uses the OpenCV for Processing library by Greg Borenstein
 * https://github.com/atduskgreg/opencv-processing
 * 
 * @Author: Jordi Tost @jorditost
 * @Author URI: jorditost.com
 *
 * University of Applied Sciences Potsdam, 2014
 */
 
import gab.opencv.*;
import SimpleOpenNI.*;
import java.awt.Rectangle;
import processing.video.*;

class StageDetector {
  
  PApplet parent;
  
  public int width;
  public int height;
  
  private OpenCV opencv;
  
  private PImage inputImage; 
  private PImage outputImage;
  
  private ArrayList<Contour> contours;
  private ArrayList<StageElement> stageElements;
  
  // Detection params
  //private float contrast = 1.35;
  //private int brightness = 0;
  private int threshold = 75; // 40: Natural light
  //private boolean useAdaptiveThreshold = false; // use basic thresholding
  //private int thresholdBlockSize = 489;
  //private int thresholdConstant = 45;
  //private int blurSize = 4;
  private int minBlobSize = 20;
  private int maxBlobSize = 200;
  
  private Boolean useColorTracking;
  
  // Color tracking params
  private int redH       = 166;  //167;
  private int greenH     = 45;   //37;
  private int blueH      = 104;  //104;
  private int rangeWidth = 10;
  
  
  //////////////////
  // Constructors
  //////////////////
  
  public StageDetector(PApplet theParent, int width, int height) {
    parent = theParent;
    useColorTracking = false;
    init(width, height);
  }
  
  public StageDetector(PApplet theParent, String pathToImg) {
    parent = theParent;
    useColorTracking = false;
    loadFromString(pathToImg);
  }
  
  public StageDetector(PApplet theParent, String pathToImg, Boolean useColorTracking) {
    parent = theParent;
    this.useColorTracking = useColorTracking;
    loadFromString(pathToImg);
  }
  
  private void loadFromString(String pathToImg) {
    PImage imageToLoad = parent.loadImage(pathToImg);
    init(imageToLoad.width, imageToLoad.height);
    detect(imageToLoad);
  }
  
  private void init(int w, int h) {
    width = w;
    height = h;
    
    // Init OpenCV
    opencv = new OpenCV(parent, width, height);
    opencv.useColor(HSB);
    
    contours = new ArrayList<Contour>();
    stageElements = new ArrayList<StageElement>();
    
    inputImage  = new PImage(width, height);
    outputImage = new PImage(width, height);
  }
  
  
  /////////////////
  // Set Methods
  /////////////////
  
  public void setThreshold(int threshold) {
    this.threshold = threshold;
  }
  
  public void setMinBlobSize(int minBlobSize) {
    this.minBlobSize = minBlobSize;
  }
  
  public void setMaxBlobSize(int maxBlobSize) {
    this.maxBlobSize = maxBlobSize;
  }
  
  public void useColorTracking() {
    useColorTracking = true;
  }
  
  public void useColorTracking(Boolean value) {
    useColorTracking = value;
  }
  
  
  ////////////////////
  // Detect Methods
  ////////////////////
  
  // Returns an array with bounding boxes
  public ArrayList<StageElement> detect(PImage img) {
    
    // Clear old contours
    contours.clear();
    stageElements.clear();
    
    // Update input image
    inputImage = img;
    opencv.loadImage(inputImage);
    
    // Blob (contour) detection
    opencv.useColor(HSB);
    opencv.setGray(opencv.getS().clone());
    outputImage = opencv.getSnapshot();
    opencv.threshold(threshold);
    opencv.erode();
    
    //outputImage = opencv.getSnapshot();
    
    contours = opencv.findContours(true, true);
  
    // Get stage elements from contours
    stageElements.addAll(getStageElements(contours, NONE));
     
    
    // Color tracking
    if (useColorTracking) {
      
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
      checkAddedElements(redStageElements, RED);
      checkAddedElements(greenStageElements, GREEN);
      checkAddedElements(blueStageElements, BLUE);
      
      /*if (method == HYBRID) {
        checkAddedElements(redStageElements, RED);
        checkAddedElements(greenStageElements, GREEN);
        checkAddedElements(blueStageElements, BLUE);
      } else {
        stageElements.addAll(redStageElements);
        stageElements.addAll(greenStageElements);
        stageElements.addAll(blueStageElements);
      }*/
    }
    
    //println("Found " + stageElements.size() + " stage elements");
    
    return stageElements;
  }
  
  private void checkAddedElements(ArrayList<StageElement> newStageElements, int type) {
    
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
  
  private boolean stageElementsAreTheSame(StageElement s1, StageElement s2) {
    
    return (abs(s1.rect.x - s2.rect.x) < 8 && 
            abs(s1.rect.y - s2.rect.y) < 8 && 
            abs(s1.rect.width - s2.rect.width) < 8 && 
            abs(s1.rect.height - s2.rect.height) < 8);
  }
  
  // Filter by color
  private ArrayList<Contour> filterContoursByColor(int hueValue) {
    
    // inputImage updated in updateVideoSource
    //opencv.loadImage(inputImage);
    
    opencv.useColor(HSB);
    opencv.setGray(opencv.getH().clone());
    opencv.inRange(hueValue-rangeWidth/2, hueValue+rangeWidth/2);
    //opencv.dilate();
    opencv.erode();
    
    return opencv.findContours(true,true);
  }
  
  // Function that filters stage elements from a given countours array
  // Returns cloned array for perform manipulation outside
  private ArrayList<StageElement> getStageElements(ArrayList<Contour> contoursArray, int type) {
    
    ArrayList<StageElement> tempStageElements = new ArrayList<StageElement>();
    
    for (Contour contour : contoursArray) {
      
      Rectangle r = contour.getBoundingBox();
      
      if (//(float(r.width)/float(displayWidth) > 0.3 || float(r.height)/float(displayWidth) > 0.3) ||
          (r.width > maxBlobSize || r.height > maxBlobSize) ||
          (r.width < minBlobSize && r.height < minBlobSize))
        continue;
      
      StageElement stageElement = new StageElement(r, type);
      tempStageElements.add(stageElement);
    }
    
    return tempStageElements;
  }
  
  
  ///////////////////////
  // Display Functions
  ///////////////////////
  
  public void displayBackground() {
    image(inputImage, 0, 0);
  }
  
  public void displayStageElements() {
    
    if (contours.size() == 0)
      return;
    
    noFill();
    strokeWeight(3);
    
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
  
  public void displayOutputImage() {
    image(outputImage, 3*width/4, 3*height/4, width/4, height/4);
  }
}
