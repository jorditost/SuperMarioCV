import gab.opencv.*;
import processing.video.*;
import java.awt.Rectangle;

Capture video;
OpenCV opencv;
PImage  background, stage, current, grayDiffImage, thresholdImage, edgesImage, contoursImage;
ArrayList<Contour> contours;
Boolean backgroundInitialized, stageInitialized;

void setup() {
  frameRate(30);

  video = new Capture(this, 640, 480);
  opencv = new OpenCV(this, video.width, video.height);
  size(int(1.5*video.width), video.height, P2D);
  contours = new ArrayList<Contour>();

  //background = createImage(video.width, video.height, RGB);
  //current = createImage(video.width, video.height, RGB);
  backgroundInitialized = stageInitialized = false;

  //opencv.useColor();
  
  video.start();
}

void draw() {
  
  // Load current frame
  opencv.useColor();
  opencv.loadImage(video);
  current = opencv.getSnapshot();
  
  // Tell OpenCV to work in HSV color space.
  opencv.useColor(HSB);
  
  // Copy the Saturation channel of our image into 
  // the gray channel, which we process.
  opencv.setGray(opencv.getS().clone());
  
  /*pushMatrix();
  scale(0.5);
  image(current, 0, 0);
  popMatrix();*/
  
  if (backgroundInitialized) {
    
    pushMatrix();
    scale(0.5);
    image(background, 0, 0);
    popMatrix();

    if (stageInitialized) {
  
      // Diff
      opencv.loadImage(background);
      opencv.diff(stage);
      grayDiffImage = opencv.getSnapshot();
  
      // Calculate Threshold
      opencv.threshold(80);
      
      // Reduce noise
      opencv.erode();
      //opencv.invert();
      thresholdImage = opencv.getSnapshot();
  
      // Contours
      contours = opencv.findContours(true,true);
      contoursImage = opencv.getSnapshot();
    
      // Edges
      opencv.loadImage(thresholdImage);
      
      // Dilate and erode to close holes
      opencv.dilate();
      opencv.erode();
      opencv.findCannyEdges(20,75);
      edgesImage = opencv.getSnapshot();
      
      pushMatrix();
      scale(0.5);
      image(stage, video.width, 0);
      image(grayDiffImage, 2*video.width, 0);
      image(thresholdImage, 2*video.width, video.height);
      image(thresholdImage, video.width, video.height);
      image(edgesImage, 0, video.height);
      
      translate(video.width, video.height);
      displayContours();
      
      popMatrix();
    }
  }

  fill(255);
  text("background", 10, 20);
  text("stage", video.width/2 +10, 20);
  text("gray diff",  video.width +10, 20);
  text("threshold", video.width + 10, video.height/2+ 20);
  text("contours", video.width/2 + 10, video.height/2+ 20);
  text("edges", 10, video.height/2+ 20);
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
    
    if (//(contour.area() > 0.9 * src.width * src.height) ||
        (r.width < 30 || r.height < 30))
      continue;
    
    stroke(255, 0, 0);
    fill(255, 0, 0, 150);
    strokeWeight(2);
    rect(r.x, r.y, r.width, r.height);
  }
}

// When a key is pressed, capture the background image into the backgroundPixels
// buffer, by copying each of the current frame's pixels into it.
void initBackground() {
  println("Background Initialized");
  opencv.useColor();
  opencv.loadImage(video);
  background = opencv.getSnapshot();

  backgroundInitialized = true;
}

void initStage() {
  println("Stage Initialized");
  opencv.useColor();
  opencv.loadImage(video);
  stage = opencv.getSnapshot();

  stageInitialized = true;
}

void keyPressed() {

  if (key == ENTER) {
    initBackground();
    //opencv.loadImage(video);
    //background = opencv.getSnapshot();
    
  } else if (key == ' ') {
    initStage();
    
    //opencv.loadImage(video);
    //background = opencv.getSnapshot();
  }
}

void captureEvent(Capture c) {
  c.read();
}

