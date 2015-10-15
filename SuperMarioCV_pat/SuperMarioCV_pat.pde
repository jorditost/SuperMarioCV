/**
 * SuperMarioCV
 *
 * @Author: Jordi Tost @jorditost
 * @Author URI: jorditost.com
 *
 * University of Applied Sciences Potsdam, 2014
 */

/*
   TO DOs
   =======
   
   TEI:
   - Green / Red parameters 
   - Green element proportions (tube vs. plant)
   - Red element proportions (bullet vs. banzai)
   
   P52DGameEngine:
   - clearDynamicBoundaries(): Only remove these platforms which were removed!!!
   - Realtime: Update Mario position but not deleting it (now it needs jumping)
 */
 
import SimpleOpenNI.*;
import gab.opencv.*;
import PostingBits.*;

import java.awt.Rectangle;

import processing.opengl.*;
import processing.video.*;

// Config vars
static boolean test = true;
static boolean showOnProjector = false;
static boolean addExtraDigitalContent = false;
static boolean polygonApproximation = false;

/*void init(){
 if (showOnProjector) {
   frame.dispose();  
   frame.setUndecorated(true);
   super.init();
 }
}*/

boolean sketchFullScreen() {
  return showOnProjector;
}

int screenWidth = 800;
int screenHeight = 600;
int backgroundColor = 255;
static float scaleFactor = 1.6; //1.25; // 1.6 is to get the 640 from the kinect to 1024

// Source vars
PImage image;
Capture video;
SimpleOpenNI kinect;

static int IMAGE_SRC = 0;
static int CAPTURE   = 1;
static int KINECT    = 2;
int source = IMAGE_SRC;

// PostingBits vars
PostingBits stage;
ArrayList<StageElement> stageElements;

// Realtime vars
Boolean realtimeDetect = true;
int t, detectionRate = 1000;
int counter = 0;

// Game Engine vars
float DOWN_FORCE = 2;
float ACCELERATION = 1.3;
float DAMPENING = 0.65; //0.5

float bulletPeriod = 5000;

MarioLevel marioLevel;


///////////
// Setup
///////////

// setup() sets up the screen size, and screen container,
// then calls the "initializeGame" method, that initializes the game

void setup() {
  
  frameRate(30);
  
  // IMAGE_SRC
  if (source == IMAGE_SRC) {
    image = loadImage("data/kitchen.jpg");
    //image = loadImage("data/stage-1280x960.jpg");
    stage = new PostingBits(this, image.width, image.height);
    
    screenWidth = 512;
    screenHeight = 432;
    scaleFactor = 0.5;
  
  // CAPTURE
  } else if (source == CAPTURE) {
    video = new Capture(this, 640, 480);
    video.start();
    stage = new PostingBits(this, 640, 480);
  
  // KINECT
  } else if (source == KINECT) {
    kinect = new SimpleOpenNI(this);
    kinect.enableRGB();
    stage = new PostingBits(this, 640, 480);
  }
  
  // Configure detector
  //stage.setContrast(1.15); // 1.15
  stage.setThreshold(60);  // 72
  stage.setDilate(true);   // true
  stage.setMinBlobSize(16);
  
  // Color Tracking
  stage.useColorTracking();
  //stage.useColorTracking(163, -100, true, 20, 170);
  stage.detectRed(165);  //166;
  //stage.detectGreen(44); //37;
  //stage.detectBlue(101); //104;
  
  // List all filter values
  stage.listFilterValues();

  // Scale screen size     
  screenWidth = int(scaleFactor*stage.width);
  screenHeight = int(scaleFactor*stage.height);
  
  // Processing 2.0 breaks in OPENGL mode with Kinect
  if (showOnProjector) {
    size(displayWidth, displayHeight);
  } else {
    size(screenWidth, screenHeight);
    //size(screenWidth, screenHeight, OPENGL);
  }
  
  if (frame != null) {
    frame.setResizable(false);
  }
  
  // set location - needs to be in setup()
  // set x parameter depending on the resolution of your 1st screen
  /*if (showOnProjector) {
    frame.setLocation(1440,0);
  }*/
    
  noLoop();
  
  t = millis();

  // Setup Game Engine
  setupGameEngine();

  // Detect stage elements and initialize game
  detectStage();
  initializeGame();
}

// Draw loop
void draw() {
  
  // Realtime detection for
  if (realtimeDetect && (millis() - t >= detectionRate)) {
    detectStage();
    updateGameStage();
    t = millis();
    
    counter++;
  }
  
  pushMatrix();
  scale(scaleFactor);
  
  // Display on Projector
  if (showOnProjector) {
    
    noStroke();
    fill(backgroundColor);
    rect(0,0,width,height);
  
  // Display on screen
  } else {
    stage.drawBackground();
    //noStroke();
    //fill(backgroundColor);
    //rect(0,0,width,height);
    
    //stage.drawStageElements();
  }
  
  if (test) {
    //stage.drawPolygonApproximation();
    //stage.drawStageElements();
    //stage.drawOutputImage();
  }
  
  popMatrix();
  
  // to do
  activeScreen.draw(); 
  SoundManager.draw();

  // Print text if new color expected
  stroke(0,0,0);
  fill(0,0,0);
  
  textSize(48);
  text(counter, 40, 70);
}

/////////////////////
// Detect Funtions
/////////////////////

void detectStage() {
  
  //ArrayList<StageElement> tempStageElements = new ArrayList<StageElement>();
  
  // 1. Load source images
  
  // IMAGE
  if (source == IMAGE_SRC) {
    stage.loadImage(image);
  
  // CAPTURE
  } else if (source == CAPTURE && video != null) {
    if (video.available()) {
      video.read();
    }
    
    stage.loadImage(video);
  
  // KINECT
  } else if (source == KINECT && kinect != null) {
    kinect.update();
    stage.loadImage(kinect.rgbImage());
  }
  
  // 2. Detect stage elements
  //ArrayList<StageElement> tempStageElements = stage.detect();  
  //stageElements = TransformUtils.scaleStageElementsArray(tempStageElements, scaleFactor);
  stageElements = stage.detect();
  //TransformUtils.scaleStageElementsArray(stageElements, scaleFactor);
}

//////////////////////////
// Jump & Run Functions
//////////////////////////

void setupGameEngine() {
  screenSet = new HashMap<String, Screen>();
  SpriteMapHandler.init(this);
  SoundManager.init(this);
  CollisionDetection.init(this);
}

void initializeGame() {
  marioLevel = new MarioLevel(width, height, stageElements);
  addScreen("level", marioLevel);
  
  counter = 0;
}

void resetGame() {
  clearScreens();
  
  // Set all objects as new
  for (StageElement stageElement : stageElements) {
    stageElement.setInitialized(false);
  }
  
  // Initialize game
  initializeGame();
}

void updateGameStage() {
  marioLevel.updatePlatforms(stageElements);
}

////////////////////
// Event Handling
////////////////////

void keyPressed() { 
  activeScreen.keyPressed(key, keyCode); 
  
  // Detect stage
  if (key == ENTER) {
      detectStage();
      updateGameStage();
      t = millis();
  
  // Reset Game
  } else if (key == BACKSPACE) {
    detectStage();
    resetGame();
  }
}

void keyReleased() { 
  activeScreen.keyReleased(key, keyCode);
}
void mouseMoved() { 
  activeScreen.mouseMoved(mouseX, mouseY);
}
void mousePressed() { 
  SoundManager.clicked(mouseX, mouseY); 
  activeScreen.mousePressed(mouseX, mouseY, mouseButton);
}
void mouseDragged() { 
  activeScreen.mouseDragged(mouseX, mouseY, mouseButton);
}
void mouseReleased() { 
  activeScreen.mouseReleased(mouseX, mouseY, mouseButton);
}
void mouseClicked() { 
  activeScreen.mouseClicked(mouseX, mouseY, mouseButton);
}

void handleCoinsTrigger(int coinsBlockId) {
 
  marioLevel.triggerCoins(coinsBlockId);  
}

///////////
// Level
///////////

class MarioLevel extends Level {
  
  MarioLayer marioLayer;
  
  // Constructor passing platforms array (stage elements)
  MarioLevel(float levelWidth, float levelHeight, ArrayList<StageElement> platformsArray) {
    super(levelWidth, levelHeight);
    marioLayer = new MarioLayer(this, platformsArray);
    addLevelLayer("layer", marioLayer);
  }
  
  public void updatePlatforms(ArrayList<StageElement> platformsArray) {
     marioLayer.updatePlatforms(platformsArray);
  }
  
  public void triggerCoins(int id) {
    marioLayer.triggerCoins(id); 
  }
}

class MarioLayer extends LevelLayer {
  
  Mario mario;
  float marioStartX = 36;
  //float marioStartX = width/12 + 25;
  float marioStartY = height-90;
  
  boolean staticTubeInitialized = false;
  float staticTubeX;
  float staticTubeY;
  float lastDynamicTubeX = -1;
  float lastDynamicTubeY = -1;
  
  //ArrayList<StageElement> dynamicPlatforms;
  
  //ArrayList<EnemyVector> muncherPositions;
  ArrayList<EnemyVector> banzaiBulletPositions;
  
  MarioLayer(Level owner, ArrayList<StageElement> platformsArray) {
    super(owner);
    
    banzaiBulletPositions = new ArrayList<EnemyVector>();
    
    // Add static platforms (walls, ground, etc.)
    addStaticPlatforms();
    
    // Add dynamic platforms (post-its)
    addDynamicPlatforms(platformsArray);
    
    // Hardcoded interactive elements (coins, koopas)
    addInteractiveElements();

    if (test) showBoundaries = true;
    mario = new Mario(marioStartX, marioStartY);
    addPlayer(mario);
  }
 
  public void updatePlatforms(ArrayList<StageElement> platformsArray) {
    
    // Clear old boundaries
    //clearDynamicPlatforms();
    
    // Clear everything except player
    clearPlatforms();
    //clearExceptPlayer();
    
    mario.updatePosition();
    
    // Add static platforms (walls, ground, etc.)
    addStaticPlatforms();
    
    // Add floating platforms (post-its)
    addDynamicPlatforms(platformsArray);
  }
  
  void clearPlatforms() {
    clearBoundaries();
    clearBackground();
    clearForeground();
    //clearDecals();
    //clearTriggers();
    //clearPickups();
    //clearInteractors();    
  }
  
  // for convenience we change the draw function
  // so that if Mario falls outside the screen,
  // we put him back at his start position:
  void draw() {
    super.draw();
    
    // Die
    if (mario.y > height && !mario.isDying) {
      mario.die();
    }
  }
  
  // Add static platforms (ground, walls, etc.)
  void addStaticPlatforms() {
    
    // Ground and walls
    addBoundary(new Boundary(-3, 0, -1, height, STATIC));
    addBoundary(new Boundary(width+1, height, width+1, 0, STATIC));
    
    // the ground now has an unjumpable gap:
    if (!addExtraDigitalContent) {
      addStaticPlatform(0, height-1, 300, height);
      addStaticPlatform(width-465, height-1, width, height);
      addStaticPlatform(width-195, height-80, width, height);
      
      // Add blocks
      addBlocks(160, height-130, 5, 1);
    
      // Add U-Blocks
      addClouds(width/2+15, 20, 4, 1);
      addClouds(width/2+15, 20+16, 1, 3);
      addClouds(width/2+15+(3*16), 20+16, 1, 3);
    
      return;
    }
    
    // Add Tubes
    //addStaticTube(124, height-350);
    //addDynamicTube(965, height-151, 40, 65);
    
    ///////////////////////////////////////////////////////////////////////////////////
    
    // Tisch / Boden-Platform
    addStaticPlatform(0, height-1, 490, height);                  //
    //addStaticPlatform(width-380, height-80, width, height);        //
    
    // MARIO 1 ZITAT W1-1 
    addBlocks(116,height-196, 1, 1);
    //addStaticPlatform(116,height-196, 16, 16);         // Pyramide +34
    addBlocks(82, height-140, 5, 1);
    //addStaticPlatform(82, height-140, 80, 16);       //////
    
    // STUFEN Mario 1 W1-1
    /*addBlocks(width-340, height-160, 1, 1);
    addBlocks(width-340, height-144, 2, 1);
    addBlocks(width-340, height-128, 3, 1);
    addBlocks(width-340, height-112, 4, 1);
    addBlocks(width-340, height-96, 5, 1);*/
    
    // U-FORM
    addBlocks(814, height-300, 8, 1);
    addBlocks(814, height-316, 1, 1);
    addBlocks(926, height-332, 1, 2);
   
    // MARIO 3 ZITAT W1-1    
    //addStaticPlatform(520, height-352, 64, 16);        // Kurz
    
    addBlocks(600, height-400, 13, 1);
    //addStaticPlatform(600, height-400, 208, 16);       // Lang
    
    // FREE LEVEL RÄTSEL    
    addClouds(622, height-516, 4, 1);
    addClouds(734, height-516, 12, 1);
    addClouds(734, height-532, 1, 1);
    addClouds(910, height-532, 1, 1);
    
    // C-FORM +   
    //addClouds(770, height-712, 1, 8);
    //addClouds(786, height-712, 4, 1);
    //addClouds(786, height-600, 4, 1);
    addClouds(682, height-688, 5, 1);

    // n-FORM      
    //addStaticPlatform(396,80,112, 16);                 // DACH
    addClouds(396,96, 1, 6);                 // Wände
    addClouds(492,96, 1, 6);                 // Wände
  
    addClouds( 32, height-430, 2, 1);        // links vom Bild  
    
    // 3 aus 5  
    //addStaticPlatform(132, 36, 800, 16);           // Lang oben links  
    addClouds( 66, 108,  1, 1);          // Block links
    addClouds(132, 108,  1, 1);          // Block links
    addClouds(198, 108,  1, 1);          // Block links
    addClouds(264, 108,  1, 1);          // Block links
    addClouds(330, 108,  1, 1);          // Block links 
    
    // REALFAKE Platform //////////////////////////////////////

    // WAGE-TEST
    //addStaticPlatform(0, height-80, width, 80);      // Wage Test /109->80=29

    /*addStaticPlatform(407, height-184, 56, 56);        // LightSwitch 
    
    addStaticPlatform( 66,height-350, 160, 16);        // BILD Lang unten links
    addStaticPlatform(262,height-350,  36, 16);        // Kurz unten rechts
    addStaticPlatform( 66,height-506, 16, 156);        // Hoch links
    addStaticPlatform( 82,height-506, 214, 16);        // Lang oben 
    addStaticPlatform(280,height-490, 16, 140);        // Hoch rechts*/
    
    //addStaticPlatform(width-132,height-91, 126, 32);     // Bilder Rahmen
    //(addStaticPlatform(width-46,height-136, 70, 16); 
    //addStaticPlatform(width-380,height-212, 64, 104);  //GAMEBOY +34
    
    ///////////////////////////////////////////////////////////////////////////////////
  }
  
  void addInteractiveElements() {
    
    // Single Mario Zitat W1-1
    addCoins(116,height-251,12);
    CoinsTrigger coinsTrigger1 = new CoinsTrigger(1, 116+12, height-251);
    addTrigger(coinsTrigger1);
    
    // Add Enemies  
    
    // Erster Koopa     // +34
    Koopa koopa1 = new Koopa(180, height-94);         // Erster links
    addInteractor(koopa1);
    
    // Koopa rechts unten    
    //Koopa koopa3 = new Koopa(width-148, height-94);    // Unten rechts
    //addInteractor(koopa3);
    
    // Koopa rechts mitte    
    Koopa koopa2 = new Koopa(width-128, height-314);   // Mitte rechts
    addInteractor(koopa2);
    
    // Kooper links oben    
    Koopa koopa4 = new Koopa(width-128, height-532);   // Oben rechts
    addInteractor(koopa4);
  }
  
  void triggerCoins(int id) {
                     
    if (id == 1) {
      
      // Add cloud coins
      addCoins(284,height-179,64);   // Postkarte COINS
      CoinsTrigger coinsTrigger2 = new CoinsTrigger(2, 284+52, height-171);
      addTrigger(coinsTrigger2);
    
    } else if (id == 2) {
      
      addCoins(530,height-119,64);   // Abgrund
      CoinsTrigger coinsTrigger3 = new CoinsTrigger(3, 530+64, height-119);
      addTrigger(coinsTrigger3);
    
    } else if (id == 3) {
      
      addCoins(600,height-448,24);   // Mario 3 W1-1 Zitat
      addCoins(648,height-432,50);   //
      addCoins(728,height-448,50);   // Mario 3 W1-1 Zitat
      
      addCoins(810,height-416,12);   // Mario 3 W1-1 Zitat
      addCoins(842,height-448,12);   //
      addCoins(874,height-432,12);   //
      addCoins(890,height-464,12);   //
      addCoins(922,height-432,12);   // Mario 3 W1-1 Zitat
      
      addCoins(width-52,height-332,24);
      addCoins(width-52,height-352,24);
      addCoins(width-52,height-372,24);
      addCoins(width-52,height-392,24);
      addCoins(width-52,height-412,24);
      addCoins(width-52,height-432,24);
      addCoins(width-52,height-452,24);
      addCoins(width-52,height-472,24);
      
      CoinsTrigger coinsTrigger4 = new CoinsTrigger(4, 600,height-448);
      addTrigger(coinsTrigger4);
    
    } else if (id == 4) {
      
       addCoins(232,height-428,12);   // im Bild
       CoinsTrigger coinsTrigger5 = new CoinsTrigger(5, 232, height-428);
       addTrigger(coinsTrigger5);
       
    } else if (id == 5) {
      
      addCoins(684,height-657,66);   // Unter C-FORM +
    
      addCoins( 66, 90, 16);          // Lücken Blöcke links oben
      addCoins(132, 146, 16);          // Block 2 links
      addCoins(198, 90, 16);          // Block 3 links    
      addCoins(264, 146, 16);          // Block 4 links
      addCoins(330, 90, 16);          // Block 5 links 
      
      // Wolken 'n' COINS    
      addCoins(436,122,26);
      addCoins(436,142,26);
      
      addCoins(32, height-400, 24);  // links vom Bild
    }
  }
  
  // Add all level platforms given a rectangles array
  void addDynamicPlatforms(ArrayList<StageElement> platformsArray) {
    for (StageElement stageElement : platformsArray) {
      
      // Get bounding box's scaled version
      Rectangle r = TransformUtils.scaleBoundingBox(stageElement.getBoundingBox(), scaleFactor);
      
      // Get tracking color
      TrackingColor trackingColor = stageElement.getTrackingColor();
      
      // It's new: do something and set it as initialized
      if (stageElement.isNew()) {
        //PApplet.println("new " + trackingColor.displayName() + " stage element! " + Math.random());
        
        // RED Elements
        if (stageElement.getTrackingColor() == TrackingColor.RED) {
          //BanzaiBullet banzai = new BanzaiBullet(r.x, r.y, r.width);
          //addInteractor(banzai);
          //checkBanzaiBill(r);
          addBanzaiBullet(stageElement.id, r);
        
        // BLUE Elements
        } else if (stageElement.getTrackingColor() == TrackingColor.BLUE) {          
            addCoins(r.x + (r.width - 14)/2, r.y - 20, 13);
            // Erster Koopa     // +34
            //Koopa koopa = new Koopa(r.x + (r.width - 14)/2, r.y - 20);         // Erster links
            //addInteractor(koopa);
        }
        
        stageElement.initialized();
      
      // Not new!
      } else {
        if (stageElement.getTrackingColor() == TrackingColor.RED) {
          checkBanzaiBullet(stageElement.id, r);
        }
      }
  
      
      // Polygon Approximation
      if (polygonApproximation) {
        Contour c = stageElement.getContour();
        Contour cApprox = c.getPolygonApproximation();
        
        ArrayList<PVector> points = cApprox.getPoints();
        
        for (PVector p : points) {
          p.mult(scaleFactor);
        }
        
        for (int i=0; i<points.size(); i++) {
          PVector p1 = points.get(i);
          PVector p2 = (i<points.size()-1) ? points.get(i+1) : points.get(0);
          addBoundary(new Boundary(p2.x, p2.y, p1.x, p1.y, DYNAMIC));
        }
        
      } else {
        addDynamicPlatform(r.x, r.y, r.width, r.height);      
      }
      
      // Check tube
      /*if (stageElement.getTrackingColor() == TrackingColor.GREEN) {
        checkTube(stageElement);
      
      // Check Banzai
      } else if (stageElement.getTrackingColor() == TrackingColor.RED) {
        checkBanzaiBill(stageElement);
        addDynamicPlatform(r.x, r.y, r.width, r.height);
        
      // General behaviour
      } else {
        addDynamicPlatform(r.x, r.y, r.width, r.height);
      }*/
    }
  }
  
  void checkTube(StageElement stageElement) {
    
    Rectangle r = stageElement.getBoundingBox();
    
    // Avoid small platforms
    if (r.width < 15 ||  
    // Avoid landscape oriented platforms
       float(r.width / r.height) > 1.5) {
         
      addDynamicPlatform(r.x, r.y, r.width, r.height);
      return;
    }
    
    // Post-it: tunnel
    if (float(r.height / r.width) < 2) {
      
      addDynamicTube(r.x, r.y, r.width, r.height);
    
    // Portrait mode: plant
    } /*else {
      boolean isNewMuncher = true;
      
      addDynamicPlatform(boundingBox.x, boundingBox.y, boundingBox.width, boundingBox.height);
        
      // Look if we already added it
      if (muncherPositions == null) {
        muncherPositions = new ArrayList<EnemyVector>();
        isNewMuncher = true;
        
      } else {
        for (EnemyVector enemyVector : muncherPositions) {
          if (abs(enemyVector.x - boundingBox.x) < 20 && abs(enemyVector.y - boundingBox.y) < 20) {
            isNewMuncher = false;
            break;
          }
        }
      }
      
      // Add new muncher
      if (isNewMuncher) {
        Muncher muncher = new Muncher(boundingBox.x+0.5*boundingBox.width, boundingBox.y-8);
        addInteractor(muncher);
        muncherPositions.add(new EnemyVector(boundingBox.x, boundingBox.y));
      }
    }*/
  }
  
  void addBanzaiBullet(int id, Rectangle r) {
    
    if (r.x < 10 || r.y < 10 || 
        float(r.height / r.width) > 5 || 
        float(r.width / r.height) > 5) {
      return;
    }
    
    BanzaiBullet banzai = new BanzaiBullet(r.x, r.y, r.width);
    addInteractor(banzai);
    
    banzaiBulletPositions.add(new EnemyVector(id, r.x, r.y));
  }
  
  void checkBanzaiBullet(int id, Rectangle r) {
    
    for (EnemyVector enemyVector : banzaiBulletPositions) {
      if (enemyVector.id == id) {
        if (millis() - enemyVector.lastUsed > bulletPeriod) {
          enemyVector.lastUsed = millis();
          
          BanzaiBullet banzai = new BanzaiBullet(r.x, r.y, r.width);
          addInteractor(banzai);
        }
      }
    }
  }
  
  /*void checkBanzaiBill(Rectangle r) {
    
    //Rectangle boundingBox = stageElement.getBoundingBox();
    
    boolean isNewBanzai = true;
    boolean reshootBanzai = false;
        
    // Look if we already added it
    if (banzaiBulletPositions == null) {
      banzaiBulletPositions = new ArrayList<EnemyVector>();
      isNewBanzai = true;
      println("ADD NEW BANZAI!!!");
      
    } else {
      for (EnemyVector enemyVector : banzaiBulletPositions) {
        if (abs(enemyVector.x - r.x) < 20 && abs(enemyVector.y - r.y) < 20) {
          isNewBanzai = false;
          
          if (millis() - enemyVector.lastUsed > bulletPeriod) {
            reshootBanzai = true;
            enemyVector.lastUsed = millis();
          }
        }
      }
    }
    
    // Add new Banzai
    if (isNewBanzai || reshootBanzai) {          
      //if (float(r.height / r.width) > 5) {
        BanzaiBullet banzai = new BanzaiBullet(r.x, r.y, r.width);
        addInteractor(banzai);
      //}
      
      // Just add if it's new
      if (isNewBanzai) {
        banzaiBulletPositions.add(new EnemyVector(1, r.x, r.y));
      }
    }
  }*/
  
  // Clear dynamic platforms
  void clearDynamicPlatforms() {
    clearDynamicBoundaries();
  }

  // Add some ground.
  void addGround(String tileset, float x1, float y1, float x2, float y2) {
    TilingSprite groundline = new TilingSprite(new Sprite("graphics/backgrounds/"+tileset+"-top.gif"), x1, y1, x2, y1+16);
    addBackgroundSprite(groundline);
    TilingSprite groundfiller = new TilingSprite(new Sprite("graphics/backgrounds/"+tileset+"-filler.gif"), x1, y1+16, x2, y2);
    addBackgroundSprite(groundfiller);
    addBoundary(new Boundary(x1, y1, x2, y1, STATIC));
  }
  
  // This creates the raised, angled sticking-out-ground bit.
  // it's actually a sprite, not a rotated generated bit of ground.
  void addSlant(float x, float y) {
    Sprite groundslant = new Sprite("graphics/backgrounds/ground-slant.gif");
    groundslant.align(LEFT, BOTTOM);
    groundslant.setPosition(x, y);
    addBackgroundSprite(groundslant);
    addBoundary(new Boundary(x, y + 48 - groundslant.height, x + 48, y - groundslant.height, STATIC));
  }

  // Add a platform with solid ground underneath.
  void addGroundPlatform(String tileset, float x, float y, float w, float h) {
    // top layer
    Sprite lc = new Sprite("graphics/backgrounds/"+tileset+"-corner-left.gif");
    lc.align(LEFT, TOP);
    lc.setPosition(x, y);
    Sprite tp = new Sprite("graphics/backgrounds/"+tileset+"-top.gif");
    Sprite rc = new Sprite("graphics/backgrounds/"+tileset+"-corner-right.gif");
    rc.align(LEFT, TOP);
    rc.setPosition(x+w-rc.width, y);
    TilingSprite toprow = new TilingSprite(tp, x+lc.width, y, x+(w-rc.width), y+tp.height);

    addBackgroundSprite(lc);
    addBackgroundSprite(toprow);
    addBackgroundSprite(rc);

    // sides/filler
    TilingSprite sideleft  = new TilingSprite(new Sprite("graphics/backgrounds/"+tileset+"-side-left.gif"), x, y+tp.height, x+lc.width, y+h);
    TilingSprite filler    = new TilingSprite(new Sprite("graphics/backgrounds/"+tileset+"-filler.gif"), x+lc.width, y+tp.height, x+(w-rc.width), y+h);
    TilingSprite sideright = new TilingSprite(new Sprite("graphics/backgrounds/"+tileset+"-side-right.gif"), x+w-rc.width, y+tp.height, x+w, y+h);

    addBackgroundSprite(sideleft);
    addBackgroundSprite(filler);
    addBackgroundSprite(sideright);

    // boundary to walk on
    addBoundary(new Boundary(x, y, x+w, y, STATIC));
  }
  
  // Add blocks
  void addBlocks(float x, float y, int nBlocksW, int nBlocksH) {
    
    float w = 16 * nBlocksW;
    float h = 16 * nBlocksH;
    
    // Load sprite
    Sprite blocksSprite = new Sprite("graphics/assorted/Cloud.png");
    //Sprite blocksSprite = new Sprite("graphics/assorted/Block.png");
    TilingSprite blocks = new TilingSprite(blocksSprite, x, y, x+w, y+h);
    addBackgroundSprite(blocks);

    addRectangle(x, y, w, h, STATIC);
  }
  
  // Add clouds
  void addClouds(float x, float y, int nBlocksW, int nBlocksH) {
    
    float w = 16 * nBlocksW;
    float h = 16 * nBlocksH;
    
    // Load sprite
    Sprite cloudsSprite = new Sprite("graphics/assorted/Cloud.png");
    TilingSprite clouds = new TilingSprite(cloudsSprite, x, y, x+w, y+h);
    addBackgroundSprite(clouds);

    addRectangle(x, y, w, h, STATIC);
  }
  
  void addRectangle(float x, float y, float w, float h, int type) {
    addBoundary(new Boundary(x, y, x+w, y, type));
    addBoundary(new Boundary(x+w, y, x+w, y+h, type));
    addBoundary(new Boundary(x+w, y+h, x, y+h, type));
    addBoundary(new Boundary(x, y+h, x, y, type));
  }
  
  // Add a dynamic platform
  void addDynamicPlatform(float x, float y, float w, float h) {
    addRectangle(x, y, w, h, DYNAMIC);
  }
  
  void addStaticPlatform(float x, float y, float w, float h) {
    addRectangle(x, y, w, h, STATIC);
  }
  
  // add coins over a horizontal stretch  
  void addCoins(float x, float y, float w) {
    float step = 16, i = 0, last = w/step;
    for(i=0; i<last; i++) {
      addForPlayerOnly(new Coin(x+8+i*step,y));
    }
  }
  
  // And finally, the end of the level!
  void addGoal(float xpos, float hpos) {
    hpos += 1;
    // background post
    Sprite goal_b = new Sprite("graphics/assorted/Goal-back.gif");
    goal_b.align(CENTER, BOTTOM);
    goal_b.setPosition(xpos, hpos);
    addBackgroundSprite(goal_b);
    // foreground post
    Sprite goal_f = new Sprite("graphics/assorted/Goal-front.gif");
    goal_f.align(CENTER, BOTTOM);
    goal_f.setPosition(xpos+32, hpos);
    addForegroundSprite(goal_f);
    // the finish line rope
    addForPlayerOnly(new Rope(xpos, hpos-16));
  }
  
  /**
   * Add a teleporter pipe
   */

  // places a single tube with all the boundaries and behaviours
  void addTube(float x, float y, TeleportTrigger teleporter) {
    // pipe head as foreground, so we can disappear behind it.
    Sprite pipe_head = new Sprite("graphics/assorted/Pipe-head.gif");
    pipe_head.align(LEFT, BOTTOM);
    pipe_head.setPosition(x, y-16);
    addForegroundSprite(pipe_head);

    // active pipe; use a removable boundary for the top
    if (teleporter!=null) {
      Boundary lid = new PipeBoundary(x, y-16-32, x+32, y-16-32);
      teleporter.setLid(lid);
      addBoundary(lid);
    }

    // plain pipe; use a normal boundary for the top
    else { 
      addBoundary(new Boundary(x, y-16-32, x+32, y-16-32));
    }

    // pipe body as background
    Sprite pipe = new Sprite("graphics/assorted/Pipe-body.gif");
    pipe.align(LEFT, BOTTOM);
    pipe.setPosition(x, y);
    addBackgroundSprite(pipe);

    if (teleporter!=null) {
      // add a trigger region for active pipes
      addTrigger(teleporter);
      // add an invisible boundery inside the pipe, so
      // that actors don't fall through when the top
      // boundary is removed.
      addBoundary(new Boundary(x+1, y-16, x+30, y-16));
      // make sure the teleport trigger has the right
      // dimensions and positioning.
      teleporter.setArea(x+16, y-20, 16, 4);
    }

    // And add side-walls, so that actors don't run
    // through the pipe as if it weren't there.
    addBoundary(new Boundary(x+32, y-16-32, x+32, y));
    addBoundary(new Boundary(x+32, y, x, y));
    addBoundary(new Boundary(x, y, x, y-16-32));
    
  }
  
  void addStaticTube(float x, float y) {
    
    staticTubeX = x + 12; //156;
    staticTubeY = y - 50; //height-120;
    
    addTube(x, y, null/*new TeleportTrigger(156,height-120)*/);
    /*if (lastDynamicTubeX != -1 && lastDynamicTubeY != -1) {
      addTube(x, y, new TeleportTrigger(lastDynamicTubeX, lastDynamicTubeY));
    } else {
      addTube(x, y, null);
    }*/
    
    staticTubeInitialized = true;
  }
  
  void addDynamicTube(float x, float y, float w, float h) {
    
    if (!staticTubeInitialized) {
      println("Couldn't add dynamic tube. Static tube isn't initialized");
      return;
    }
    
    TeleportTrigger teleporter = new TeleportTrigger(staticTubeX, staticTubeY);
    
    // active pipe; use a removable boundary for the top
    Boundary lid = new PipeBoundary(x, y, x+w, y);
    teleporter.setLid(lid);
    addBoundary(lid);
      
    // add a trigger region for active pipes
    addTrigger(teleporter);
    // add an invisible boundery inside the pipe, so
    // that actors don't fall through when the top
    // boundary is removed.
    addBoundary(new Boundary(x, y+h-2, x+w, y+h-2));
  
    // make sure the teleport trigger has the right
    // dimensions and positioning.
    teleporter.setArea(x+w/2, y+10, w/2, 2);

    // And add side-walls, so that actors don't run
    // through the pipe as if it weren't there.
    
    addBoundary(new Boundary(x+w, y, x+w, y+h));
    addBoundary(new Boundary(x+w, y+h, x, y+h));
    addBoundary(new Boundary(x, y+h, x, y));
    
    lastDynamicTubeX = x;
    lastDynamicTubeY = y+h-2;
  }
  
  // places a single tube with all the boundaries and behaviours, upside down
  void addUpsideDownTube(float x, float y) {
    // pipe body as background
    Sprite pipe = new Sprite("graphics/assorted/Pipe-body.gif");
    pipe.align(LEFT, TOP);
    pipe.setPosition(x, y);
    addBackgroundSprite(pipe);

    // pipe head as foreground, so we can disappear behind it.
    Sprite pipe_head = new Sprite("graphics/assorted/Pipe-head.gif");
    pipe_head.align(LEFT, TOP);
    pipe_head.flipVertical();
    pipe_head.setPosition(x, y+16);
    addForegroundSprite(pipe_head);

    // And add side-walls and the bottom "lid.
    addBoundary(new Boundary(x, y+16+32, x, y));
    addBoundary(new Boundary(x+32, y, x+32, y+16+32));

    addBoundary(new Boundary(x+32, y+16+32, x, y+16+32));
  }
}

//////////////////
// Player Class
//////////////////

class Mario extends Player {

  int score = 0;
  float speed = 2.5;//4;
  float jumpImpulse = -55;//-80;
  float initX, initY;
  boolean isDying;
  
  boolean canShoot = false;

  Mario(float x, float y) {
    super("Mario");
    setupStates();
    setCurrentState("idle");
    setPosition(x, y);
    initX = x;
    initY = y;
    handleKey('W');
    //handleKey(char(UP));
    handleKey(char(RIGHT));
    handleKey(char(LEFT));
    handleKey(char(DOWN));
    setForces(0, DOWN_FORCE);
    setAcceleration(0, ACCELERATION);
    setImpulseCoefficients(DAMPENING, DAMPENING);
    isDying = false;
  }
  
  void addState(State st) {
    st.sprite.anchor(CENTER, BOTTOM);
    super.addState(st);
  }

  void setupStates() {
    
    // idling state
    addState(new State("idle", "graphics/mario/small/Standing-mario.gif"));
    
    // crouching state
    addState(new State("crouching", "graphics/mario/small/Crouching-mario.gif"));
    
    // running state
    addState(new State("running", "graphics/mario/small/Running-mario.gif", 1, 4));
    
    // dead state
    State dead = new State("dead", "graphics/mario/small/Dead-mario.gif", 1, 2);
    dead.setAnimationSpeed(0.25);
    dead.setDuration(15);
    addState(dead);
    SoundManager.load(dead, "audio/Dead.mp3");
  
    // jumping state
    State jumping = new State("jumping", "graphics/mario/small/Jumping-mario.gif");
    jumping.setDuration(10);
    addState(jumping);
    SoundManager.load(jumping, "audio/Jump.mp3");
    
    State crouchjumping = new State("crouchjumping", "graphics/mario/small/Crouching-mario.gif");
    crouchjumping.setDuration(15);
    addState(crouchjumping);
    SoundManager.load(crouchjumping, "audio/Jump.mp3");
    
    // being hit requires a sound effect too
    SoundManager.load("mario hit", "audio/Pipe.mp3");
  }
  
  // what happens when we touch another player or NPC?
  void overlapOccurredWith(Actor other, float[] direction) {
    
    if (other instanceof Koopa) {
      // get a reference to this Koopa trooper
      Koopa koopa = (Koopa) other;
      
      // get the angle at which we've impacted with this koopa trooper
      float angle = direction[2];
 
      // Now to find out whether we bopped a koopa on the head!
      float tolerance = radians(75);
      if (PI/2 - tolerance <= angle && angle <= PI/2 + tolerance) {
        // we hit it from above!
        // 1) squish the koopa trooper
        koopa.hit();
        // Stop moving in whichever direction we were moving in
        stop(0,0);
        // instead, jump up!
        setImpulse(0, -30);
        setCurrentState("jumping");
      }
 
      // if we didn't hit it at the correct angle, we still die =(
      else { die(); }
    
    } else if (other instanceof BanzaiBill || other instanceof BanzaiBullet || other instanceof Muncher) {
      die();  
    }
  }

  void die() {
    // switch to dead state
    setCurrentState("dead");
    // turn off interaction, so we don't flag more touching koopas or pickups or walls, etc.
    setInteracting(false);
    // make up jump up in an "oh no!" fashion
    addImpulse(0,-70);
    // and turn up gravity so we fall down quicker than usual.
    //setForces(0,3);
    
    isDying = true;
    
    SoundManager.play(active);
  }
  
  void resurrect() {
    removeActor();
    resetGame();
  }
  
  void updatePosition() {
    //addImpulse(0, -2);
    //jsupdate();
    //verifyInMotion();
  }
 
  void handleStateFinished(State which) {
    
    if (which.name == "dead") {
      //println("DEAD FINISHED!");
      resurrect();
      //removeActor();
      //resetGame();
    } 
    else {
      setCurrentState("idle");
    }
  }

  // Keyboard interaction
  void handleInput() {
    
    // we don't handle any input when we're dead~
    if (active.name=="dead" || active.name=="won") return;
    if (isDying) return;

    // what do we "do"? (i.e. movement wise)
    if (active.name!="crouching" && (isKeyDown(char(LEFT)) || isKeyDown(char(RIGHT)))) {
      if (isKeyDown(char(LEFT))) {
        // when we walk left, we need to flip the sprite
        setHorizontalFlip(true);
        // walking left means we get a negative impulse along the x-axis:
        addImpulse(-speed, 0);
        // and we set the viewing direction to "left"
        setViewDirection(-1, 0);
      }
      if (isKeyDown(char(RIGHT))) {
        // when we walk right, we need to NOT flip the sprite =)
        setHorizontalFlip(false);
        // walking right means we get a positive impulse along the x-axis:
        addImpulse(speed, 0);
        // and we set the viewing direction to "right"
        setViewDirection(1, 0);
      }
    }

    // if the jump key is pressed, and we're standing on something, let's jump! 
    if (active.mayChange() && isKeyDown('W') && boundaries.size()>0) {
      ignore('W');
      // generate a massive impulse upward
      addImpulse(0, jumpImpulse);
      // and make sure we look like we're jumping, too
      if (active.name!="crouching") {
        setCurrentState("jumping");
      } else {
        setCurrentState("crouchjumping");
      }
      SoundManager.play(active);
    }

    // if we're not jumping, but left or right is pressed,
    // make sure we're using the "running" state.
    if (isKeyDown(char(DOWN))) {
      if (boundaries.size()>0) {
        for(Boundary b: boundaries) {
          if(b instanceof PipeBoundary) {
            ((PipeBoundary)b).trigger(this);
          }
        }
      }
      if (active.name=="jumping") { setCurrentState("crouchjumping"); }
      else { setCurrentState("crouching"); }
    }

    // and what do we look like when we do this?
    if (active.mayChange())
    {
      if (active.name!="crouching" && (isKeyDown(char(LEFT)) || isKeyDown(char(RIGHT)))) {
       setCurrentState("running");
      }

      // if we're not actually doing anything,
      // then we change the state to "idle"
      else if (noKeysDown()) {
        setCurrentState("idle");
      }
    }
  }

  /**
   * What happens when we get pickups?
   */
  void pickedUp(Pickup pickup) {
    // we got some points
    if (pickup.name=="Regular coin") {
      score++;
    }
    // we got big points
    else if (pickup.name=="Dragon coin") {
      score+=100;
    }
  }
}

