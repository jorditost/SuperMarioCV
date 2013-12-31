import gab.opencv.*;
import java.awt.Rectangle;

int screenWidth = 512;
int screenHeight = 432;

// Jump & Run vars
float DOWN_FORCE = 2;
float ACCELERATION = 1.3;
float DAMPENING = 0.75;

// Background Detection vars
OpenCV opencv;
PImage  background;

// setup() sets up the screen size, and screen container,
// then calls the "initialize" method, which you must
// implement yourself.

void setup() {
  background = loadImage("after4.jpg");
  
  screenWidth = int(0.5*background.width);
  screenHeight = int(0.5*background.height);
  size(screenWidth, screenHeight);
  noLoop();

  screenSet = new HashMap<String, Screen>();
  SpriteMapHandler.init(this);
  SoundManager.init(this);
  CollisionDetection.init(this);
  initialize();
  
  frameRate(30);
}

// Draw loop
void draw() {
  
  pushMatrix();
  scale(0.5);
  image(background, 0, 0);
  popMatrix();
  
  activeScreen.draw(); 
  SoundManager.draw();
  
//  stroke(255, 0, 0);
//  fill(255, 0, 0, 150);
//  strokeWeight(2);
//  rect(width/2, height/2, 40, 40);
}

//////////////////////////
// Jump & Run Functions
//////////////////////////

void initialize() {
  addScreen("level", new MarioLevel(width, height));
}

class MarioLevel extends Level {
  MarioLevel(float levelWidth, float levelHeight) {
    super(levelWidth, levelHeight);
    addLevelLayer("layer", new MarioLayer(this));
  }
}
 
class MarioLayer extends LevelLayer {
  MarioLayer(Level owner) {
    super(owner);
    
    // Ground and walls
    addBoundary(new Boundary(0,height-2,138,height-48));
    addBoundary(new Boundary(138,height-48,width,height-48));
    //addBoundary(new Boundary(0,height-48,width,height-48));
    addBoundary(new Boundary(-1,0, -1,height));
    addBoundary(new Boundary(width+1,height, width+1,0));
    
    // Stage boundaries
    // add some ground platforms, some with coins
    addGroundPlatform("ground", 40+width/2, height-144, 40, 90);
    addGroundPlatform("ground", width/2, height-96, 68, 48);
    
    // Add floating platforms (post-its)
    addFloatingPlatform(250, 190, 30, 30);
    addFloatingPlatform(300, 132, 30, 28);
    addFloatingPlatform(368, 165, 30, 30);
    
    addFloatingPlatform(width-52, height-78, 33, 30);
    
    //showBoundaries = true;
    Mario mario = new Mario(width/2, height/2);
    addPlayer(mario);
  }
  
  // Add some ground.
  void addGround(String tileset, float x1, float y1, float x2, float y2) {
    TilingSprite groundline = new TilingSprite(new Sprite("graphics/backgrounds/"+tileset+"-top.gif"), x1,y1,x2,y1+16);
    addBackgroundSprite(groundline);
    TilingSprite groundfiller = new TilingSprite(new Sprite("graphics/backgrounds/"+tileset+"-filler.gif"), x1,y1+16,x2,y2);
    addBackgroundSprite(groundfiller);
    addBoundary(new Boundary(x1,y1,x2,y1));
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
    TilingSprite sideleft  = new TilingSprite(new Sprite("graphics/backgrounds/"+tileset+"-side-left.gif"),  x,            y+tp.height, x+lc.width,     y+h);
    TilingSprite filler    = new TilingSprite(new Sprite("graphics/backgrounds/"+tileset+"-filler.gif"),     x+lc.width,   y+tp.height, x+(w-rc.width), y+h);
    TilingSprite sideright = new TilingSprite(new Sprite("graphics/backgrounds/"+tileset+"-side-right.gif"), x+w-rc.width, y+tp.height, x+w,            y+h);

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
}

class Mario extends Player {
  Mario(float x, float y) {
    super("Mario");
    setupStates();
    setPosition(x,y);
    handleKey(char(UP));
    handleKey(char(RIGHT));
    handleKey(char(LEFT));
    setForces(0,DOWN_FORCE);
    setAcceleration(0,ACCELERATION);
    setImpulseCoefficients(DAMPENING,DAMPENING);
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
  
  void handleStateFinished(State which) {
    setCurrentState("idle");
  }
  
  void handleInput() {
    // handle running
    if(isKeyDown(char(LEFT)) || isKeyDown(char(RIGHT))) {
      if (isKeyDown(char(LEFT))) {
        setHorizontalFlip(true);
        addImpulse(-2, 0);
      }
      if (isKeyDown(char(RIGHT))) {
        setHorizontalFlip(false);
        addImpulse(2, 0);
      }
    }
 
    // handle jumping
    if(isKeyDown(char(UP)) && active.name!="jumping" && boundaries.size()>0) {
      addImpulse(0,-35);
      setCurrentState("jumping");
    }
    
    if (active.mayChange()) {
      if(isKeyDown(char(LEFT)) || isKeyDown(char(RIGHT))) {
        setCurrentState("running");
      }
      else { setCurrentState("idle"); }
    }
  }
}
