import gab.opencv.*;
import java.awt.Rectangle;

boolean test = true;

int screenWidth = 512;
int screenHeight = 432;
float scaleFactor = 0.5;

// Jump & Run vars
float DOWN_FORCE = 2;
float ACCELERATION = 1.3;
float DAMPENING = 0.75;

// Background Detection vars
StageDetector stage;
ArrayList<Rectangle> stageElements;

// Realtime vars
Boolean realtimeDetect = false;

///////////
// Setup
///////////

// setup() sets up the screen size, and screen container,
// then calls the "initializeGame" method, that initializes the game

void setup() {

  stage = new StageDetector(this, "after4.jpg");
  //stage = new StageDetector(this, 640, 480, CAPTURE);
  //stage = new StageDetector(this, 640, 480);
  stage.setSource(CAPTURE);
  stage.setMethod(EDGES);

  screenWidth = int(scaleFactor*stage.width);
  screenHeight = int(scaleFactor*stage.height);

  size(screenWidth, screenHeight);
  noLoop();

  // Setup Game Engine
  setupGameEngine();

  // Detect stage elements and initialize game
  stageElements = scaleRectanglesArray(stage.detect(), scaleFactor);
  initializeGame();

  frameRate(30);
}

// Draw loop
void draw() {
  
  if (stage.method == EDGES && realtimeDetect)
    detectStage();
  }
  
  pushMatrix();
  scale(scaleFactor);
  stage.displayBackground();
  if (test) stage.displayContours();
  popMatrix();
  
  // to do
  activeScreen.draw(); 
  SoundManager.draw();
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
  addScreen("level", new MarioLevel(width, height, stageElements));
}

void resetGame() {
  clearScreens();
  addScreen("level", new MarioLevel(width, height, stageElements));
}

void updateGameStage() {
  // TO DO: Update MarioLevel object with new stageElements but not create new
}

void detectStage() {
  println(">>>>> DETECT!");
  stageElements = scaleRectanglesArray(stage.detect(), scaleFactor);
}

////////////////////
// Event Handling
////////////////////

void keyPressed() { 
  activeScreen.keyPressed(key, keyCode); 
  
  // Update background image
  if (key == ENTER) {
      
    stage.initBackground();
    
    // Detect for Edges Detection
    if (stage.method == EDGES) {
      detectStage();
      resetGame();
    }
  
  // Update stage elements (post-its, etc)
  } else if (key == ' ') {
    
    // Detect for Image Diff Detection
    if (stage.method == IMAGE_DIFF) {
      stage.initStage();
      detectStage();
      resetGame();
    }
  
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


///////////
// Level
///////////

class MarioLevel extends Level {

  // Constructor passing platforms array (stage elements)
  MarioLevel(float levelWidth, float levelHeight, ArrayList<Rectangle> platformsArray) {
    super(levelWidth, levelHeight);
    addLevelLayer("layer", new MarioLayer(this, platformsArray));
  }
}

class MarioLayer extends LevelLayer {

  MarioLayer(Level owner, ArrayList<Rectangle> platformsArray) {
    super(owner);

    // Ground and walls
    addBoundary(new Boundary(0, height-2, 138, height-48));
    addBoundary(new Boundary(138, height-48, width, height-48));
    //addBoundary(new Boundary(0,height-48,width,height-48));
    addBoundary(new Boundary(-1, 0, -1, height));
    addBoundary(new Boundary(width+1, height, width+1, 0));

    // Add some ground platforms, some with coins
    addGroundPlatform("ground", 40+width/2, height-144, 40, 90);
    addGroundPlatform("ground", width/2, height-96, 68, 48);

    // Add floating platforms (post-its)
    addLevelPlatforms(platformsArray);

    if (test) showBoundaries = true;
    Mario mario = new Mario(width/2, height/2);
    addPlayer(mario);
  }

  // Add some ground.
  void addGround(String tileset, float x1, float y1, float x2, float y2) {
    TilingSprite groundline = new TilingSprite(new Sprite("graphics/backgrounds/"+tileset+"-top.gif"), x1, y1, x2, y1+16);
    addBackgroundSprite(groundline);
    TilingSprite groundfiller = new TilingSprite(new Sprite("graphics/backgrounds/"+tileset+"-filler.gif"), x1, y1+16, x2, y2);
    addBackgroundSprite(groundfiller);
    addBoundary(new Boundary(x1, y1, x2, y1));
  }  

  // This creates the raised, angled sticking-out-ground bit.
  // it's actually a sprite, not a rotated generated bit of ground.
  void addSlant(float x, float y) {
    Sprite groundslant = new Sprite("graphics/backgrounds/ground-slant.gif");
    groundslant.align(LEFT, BOTTOM);
    groundslant.setPosition(x, y);
    addBackgroundSprite(groundslant);
    addBoundary(new Boundary(x, y + 48 - groundslant.height, x + 48, y - groundslant.height));
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
    addBoundary(new Boundary(x, y, x+w, y));
  }

  // Add a floating platform
  void addFloatingPlatform(float x, float y, float w, float h) {
    addBoundary(new Boundary(x, y, x+w, y));
    addBoundary(new Boundary(x+w, y, x+w, y+h));
    addBoundary(new Boundary(x+w, y+h, x, y+h));
    addBoundary(new Boundary(x, y+h, x, y));
  }

  // Add all level platforms given a rectangles array
  void addLevelPlatforms(ArrayList<Rectangle> platformsArray) {
    for (Rectangle r : platformsArray) {
      addFloatingPlatform(r.x, r.y, r.width, r.height);
    }
  }
}

//////////////////
// Player Class
//////////////////

class Mario extends Player {

  int score = 0;
  float speed = 2;
  float initX, initY;

  Mario(float x, float y) {
    super("Mario");
    setupStates();
    setPosition(x, y);
    initX = x;
    initY = y;
    handleKey(char(UP));
    handleKey(char(RIGHT));
    handleKey(char(LEFT));
    setForces(0, DOWN_FORCE);
    setAcceleration(0, ACCELERATION);
    setImpulseCoefficients(DAMPENING, DAMPENING);
  }

  void setupStates() {
    addState(new State("idle", "graphics/mario/small/Standing-mario.gif"));
    addState(new State("running", "graphics/mario/small/Running-mario.gif", 1, 4));

    State dead = new State("dead", "graphics/mario/small/Dead-mario.gif", 1, 2);
    dead.setAnimationSpeed(0.25);
    dead.setDuration(100);
    addState(dead);   

    State jumping = new State("jumping", "graphics/mario/small/Jumping-mario.gif");
    jumping.setDuration(12);
    addState(jumping);

    setCurrentState("idle");
  }

  /*public void restart() {
   removeActor();
   //reset();
   setCurrentState("idle");
   //setPosition(initX, initY);
   }*/

  void handleStateFinished(State which) {
    if (which.name == "dead") {
      removeActor();
      resetGame();
    } 
    else {
      setCurrentState("idle");
    }
  }

  // Keyboard interaction
  void handleInput() {

    // handle running
    if (isKeyDown(char(LEFT)) || isKeyDown(char(RIGHT))) {
      if (isKeyDown(char(LEFT))) {
        setHorizontalFlip(true);
        addImpulse(-speed, 0);
      }
      if (isKeyDown(char(RIGHT))) {
        setHorizontalFlip(false);
        addImpulse(speed, 0);
      }
    }

    // handle jumping
    if (isKeyDown(char(UP)) && active.name!="jumping" && boundaries.size()>0) {
      addImpulse(0, -35);
      setCurrentState("jumping");
    }

    if (active.mayChange()) {
      if (isKeyDown(char(LEFT)) || isKeyDown(char(RIGHT))) {
        setCurrentState("running");
      }
      else { 
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

/**
 * All pickups in Mario may move, and if
 * they do, they will bounce when hitting
 * a clean boundary.
 */
class MarioPickup extends Pickup {
  MarioPickup(String name, String spritesheet, int rows, int columns, float x, float y, boolean visible) {
    super(name, spritesheet, rows, columns, x, y, visible);
  }
  void gotBlocked(Boundary b, float[] intersection) {
    if (intersection[0]-x==0 && intersection[1]-y==0) {
      fx = -fx;
      active.sprite.flipHorizontal();
    }
  }
}

/**
 * A regular coin
 */
class Coin extends MarioPickup {
  Coin(float x, float y) {
    super("Regular coin", "graphics/assorted/Regular-coin.gif", 1, 4, x, y, true);
  }
}


/**
 * A dragon coin!
 */
class DragonCoin extends MarioPickup {
  DragonCoin(float x, float y) {
    super("Dragon coin", "graphics/assorted/Dragon-coin.gif", 1, 10, x, y, true);
  }
}

