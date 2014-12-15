/**
 * StageDetector Class
 * Uses the OpenCV for Processing library by Greg Borenstein
 * https://github.com/atduskgreg/opencv-processing
 * 
 * @Author: Jordi Tost @jorditost
 * @Author URI: jorditost.com
 * @version: 0.2-beta
 *
 * University of Applied Sciences Potsdam, 2014
 */
 
import gab.opencv.*;
import SimpleOpenNI.*;
import java.awt.Rectangle;
import processing.video.*;

public static String version = "v0.2-beta";

// declare like:
// enum TrackingColorMode {TRACK_COLOR_RGB, TRACK_COLOR_HSV, TRACK_COLOR_H, TRACK_COLOR_HS};
public static final int GRAY = 0;  // More stable with video source
public static final int S    = 1;

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
  private int channel = S;
  private float contrast = 1;
  private int brightness = 0;
  private int threshold = 75; // 40: Natural light
  private boolean useAdaptiveThreshold = false; // use basic thresholding
  private int thresholdBlockSize = 500; //489;
  private int thresholdConstant = -20; //45;
  private boolean dilate = false;
  private boolean erode = true;
  private int blurSize = 1;
  private boolean useThresholdAfterBlur = false;
  private int thresholdAfterBlur = 75;
  private int minBlobSize = 20;
  private int maxBlobSize = 400;
  
  private boolean useColorTracking;
  
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
  
  public StageDetector(PApplet theParent, String pathToImg, boolean useColorTracking) {
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
    
    //inputImage  = new PImage(width, height);
    //outputImage = new PImage(width, height);
  }
  
  ////////////////
  // Print Info
  ////////////////
  
  public void listFilterValues() {
    println(" ");
    println("StageDetector " + version);
    println("========================");
    println("- Channel:                 " + ((channel == S) ? "Saturation" : "Gray"));
    println("- Contrast:                " + contrast);
    //println("- Brightness:            " + brightness);
    if (useAdaptiveThreshold) {
      println("- Adaptive Threshold");
      println("    Block Size:            " + thresholdBlockSize);
      println("    Constant:              " + thresholdConstant);
    } else {
      println("- Threshold:               " + threshold);
    }
    println("- Blur Size:               " + blurSize);
    if (useThresholdAfterBlur) {
      println("- Threshold (after blur):  " + thresholdAfterBlur);
    }
    println("- Min. Blob Size:          " + minBlobSize);
    println("- Max. Blob Size:          " + maxBlobSize);
    println(" ");
  }
  
  /////////////////
  // Set Methods
  /////////////////
  
  public void setChannel(int channel) {
    this.channel = channel;
  }
  
  public void setContrast(float contrast) {
    this.contrast = contrast;
  }
  
  public void setThreshold(int threshold) {
    this.threshold = threshold;
  }
  
  public void setUseAdaptiveThreshold(boolean flag) {
    this.useAdaptiveThreshold = flag;
  }
  
  public void setThresholdBlockSize(int value) {
    this.thresholdBlockSize = value;
  }
  
  public void setThresholdConstant(int value) {
    this.thresholdConstant = value;
  }
  
  public void setDilate(boolean flag) {
    this.dilate = flag;
  }
  
  public void setErode(boolean flag) {
    this.erode = flag;
  }
  
  public void setBlurSize(int blurSize) {
    this.blurSize = blurSize;
  }
  
  public void setUseThresholdAfterBlur(boolean flag) {
    this.useThresholdAfterBlur = flag;
  }
  
  public void setThresholdAfterBlur(int value) {
    this.thresholdAfterBlur = value;
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
  
  public void useColorTracking(boolean value) {
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
    
    // Load new image into OpenCV
    inputImage = img;
    opencv.loadImage(inputImage);
    
    // Blob (contour) detection
    /*opencv.useColor(HSB);
    opencv.setGray(opencv.getS().clone());
    opencv.threshold(threshold);
    opencv.erode();*/
    
    ///////////////////////////////
    // <1> PRE-PROCESS IMAGE
    // - Detection channel 
    // - Brightness / Contrast
    ///////////////////////////////
    
    // Detection channel
    if (channel == S) {
      opencv.useColor(HSB);
      opencv.setGray(opencv.getS().clone());
    } else {
      opencv.gray();
    }
    
    // Contrast
    //opencv.brightness(brightness);
    if (contrast > 1) {
      opencv.contrast(contrast);
    }
    
    ///////////////////////////////
    // <2> PROCESS IMAGE
    // - Threshold
    // - Noise Supression
    ///////////////////////////////
      
    // Adaptive threshold - Good when non-uniform illumination
    if (useAdaptiveThreshold) {
      
      // Block size must be odd and greater than 3
      if (thresholdBlockSize%2 == 0) thresholdBlockSize++;
      if (thresholdBlockSize < 3) thresholdBlockSize = 3;
      
      opencv.adaptiveThreshold(thresholdBlockSize, thresholdConstant);
      
    // Basic threshold - range [0, 255]
    } else {
      opencv.threshold(threshold);
    }
  
    // Invert (black bg, white blobs)
    if (channel == GRAY) {
      opencv.invert();
    }
    
    // Reduce noise - Dilate and erode to close holes
    // Reduce noise - Dilate and erode to close holes
    if (dilate) opencv.dilate();
    if (erode)  opencv.erode();
    
    // Blur
    if (blurSize > 1) {
      opencv.blur(blurSize);
    }
    
    if (useThresholdAfterBlur) {
      opencv.threshold(thresholdAfterBlur);
    }
    
    // Save snapshot for display
    //outputImage = opencv.getSnapshot();
    
    ///////////////////////////////
    // <3> FIND CONTOURS  
    ///////////////////////////////
    
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
  
  private void checkAddedElements(ArrayList<StageElement> newStageElements, int colorId) {
    
    for (StageElement newStageElement : newStageElements) {
      
      boolean isAdded = false;
      for (int i=0; i < stageElements.size(); i++) {
        StageElement stageElement = stageElements.get(i);
        
        // Check if they are the same
        if (stageElementsAreTheSame(stageElement, newStageElement)) {
          stageElement.colorId = colorId;
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
  private ArrayList<StageElement> getStageElements(ArrayList<Contour> contoursArray, int colorId) {
    
    ArrayList<StageElement> tempStageElements = new ArrayList<StageElement>();
    
    for (Contour contour : contoursArray) {
      
      Rectangle r = contour.getBoundingBox();
      
      if (//(float(r.width)/float(displayWidth) > 0.3 || float(r.height)/float(displayWidth) > 0.3) ||
          (r.width > maxBlobSize || r.height > maxBlobSize) ||
          (r.width < minBlobSize && r.height < minBlobSize))
        continue;
      
      StageElement stageElement = new StageElement(r, colorId);
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
    
    for (StageElement stageElement : stageElements) {
      stageElement.display();
    }
  }
  
  public void displayOutputImage() {
    //image(outputImage, 3*width/4, 3*height/4, width/4, height/4);
  }
}
