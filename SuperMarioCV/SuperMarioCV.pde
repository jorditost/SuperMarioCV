/**
 * SuperMarioCV
 *
 * University of Applied Sciences Potsdam, 2013-2014
 */

/*
   TO DOs
   =======
   
   - Plants / Fire -> Interaktion // displayStageElements()
   - Mario soll nicht rutschen
   - Realtime
   
   
   StageDetector:
   - Unify display() and displayBackground() functions for all detection methods and sources
   
   P52DGameEngine:
   - clearDynamicBoundaries(): Do we need it?
   - Realtime: Update Mario position but not deleting it (now it needs jumping)
 */
 
import processing.opengl.*;
import gab.opencv.*;

boolean test = true;
boolean showOnProjector = false;
Boolean realtimeDetect = true;

int screenWidth = 512;
int screenHeight = 432;
float scaleFactor = 0.5;

//int screenWidth = 800;
//int screenHeight = 600;
//float scaleFactor = 1.25;

int backgroundColor = 0;

// Jump & Run vars
float DOWN_FORCE = 2;
float ACCELERATION = 1.3;
float DAMPENING = 0.75;

// Level vars
MarioLevel marioLevel;

// Background Detection vars
StageDetector stage;
ArrayList<StageElement> stageElements;

// Realtime vars
int t, detectionRate = 2000;

///////////
// Setup
///////////

// setup() sets up the screen size, and screen container,
// then calls the "initializeGame" method, that initializes the game

void setup() {

  stage = new StageDetector(this, "input/after4.jpg");
  //stage = new StageDetector(this, 640, 480, KINECT);
  //stage.setSource(CAPTURE);
  stage.setMethod(COLOR_FILTER);
  //stage.setMethod(EDGES);
  //stage.setEdgesThreshold(70);

  screenWidth = int(scaleFactor*stage.width);
  screenHeight = int(scaleFactor*stage.height);

  size(screenWidth, screenHeight, OPENGL);
  
  // set location - needs to be in setup()
  // set x parameter depending on the resolution of your 1st screen
  if (showOnProjector) {
    frame.setLocation(1440,0);
  }
  
  noLoop();
  
  t = millis();

  // Setup Game Engine
  setupGameEngine();

  // Detect stage elements and initialize game
  stageElements = scaleStageElementsArray(stage.detect(), scaleFactor);
  initializeGame();

  frameRate(30);
}

// Draw loop
void draw() {
  
  // Realtime detection for
  if ((stage.method == EDGES || stage.method == COLOR_FILTER) && realtimeDetect && (millis() - t >= detectionRate)) {
    detectStage();
    updateGameStage();
    t = millis();
  }
  
  pushMatrix();
  scale(scaleFactor);
  
  if (showOnProjector) {
    
    noStroke();
    fill(backgroundColor);
    rect(0,0,width,height);
    
    /*if (realtimeDetect) {
      noStroke();
      fill(0);
      rect(0,0,width,height);
    } else {
      stage.displayBackground();  
    }*/
    
    if (test) stage.displayStageElements();
    
  } else {
    if (realtimeDetect) {
      stage.display();
    } else {
      stage.displayBackground();  
    }
    
    if (test) stage.displayStageElements();
  }
  
  popMatrix();
  
  // to do
  activeScreen.draw(); 
  SoundManager.draw();
}

/*void init(){
 if (showOnProjector) {
   frame.dispose();  
   frame.setUndecorated(true);
   super.init();
 }
}*/


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
}

void resetGame() {
  clearScreens();
  initializeGame();
}

void updateGameStage() {
  marioLevel.updatePlatforms(stageElements);
}

void detectStage() {
  stageElements = scaleStageElementsArray(stage.detect(), scaleFactor);
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
  
  MarioLayer marioLayer;
  
  // Constructor passing platforms array (stage elements)
  MarioLevel(float levelWidth, float levelHeight, ArrayList<StageElement> platformsArray) {
    super(levelWidth, levelHeight);
    marioLayer = new MarioLayer(this, platformsArray);
    addLevelLayer("layer", marioLayer);
  }
  
//  void updateMario(Player mario_new) {
//    updatePlayer(mario, mario_new);
//    mario = mario_new;
//  }
  
  public void updatePlatforms(ArrayList<StageElement> platformsArray) {
     marioLayer.updatePlatforms(platformsArray);
  }
}

class MarioLayer extends LevelLayer {
  
  Mario mario;
  float marioStartX = width/12 + 30;
  float marioStartY = height/2;
  
  ArrayList<StageElement> dynamicPlatforms;
  
  MarioLayer(Level owner, ArrayList<StageElement> platformsArray) {
    super(owner);
    
    // Add static platforms (walls, ground, etc.)
    addStaticPlatforms();
    
    // Add dynamic platforms (post-its)
    addDynamicPlatforms(platformsArray);
    
    // Add Coins
    addCoins(width-160,height-70,68);
    addCoins(364,105,68);
    /*addCoins(247,200,12);
    addCoins(247,180,12);
    addCoins(247,160,12);
    addCoins(247,140,12);*/
    
    // Add Pipes
    // add two teleporters on either side of the gap
    /*Pipe t1 = addPipe(width/4-16, height-48);
    Pipe t2 = addPipe(3*width/4-64, height-48);
 
    // and link them together
    t1.teleportTo(t2);
    t2.teleportTo(t1);*/

    // Add Enemies
    Koopa koopa = new Koopa(width/4, height-178);
    addInteractor(koopa);
    
    Koopa koopa2 = new Koopa(280, 100);
    addInteractor(koopa2);

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
  
  // Add static platforms (ground, walls
  void addStaticPlatforms() {
    // Ground and walls
    addBoundary(new Boundary(-1, 0, -1, height, STATIC));
    addBoundary(new Boundary(width+1, height, width+1, 0, STATIC));

    // Add some ground platforms, some with coins
    //addGroundPlatform("ground", 40+width/2, height-144, 40, 90);
    //addGroundPlatform("ground", width/2, height-96, 68, 48);
    
    //addGroundPlatform("ground", 0, height-40, width/4, 40);
    //addGroundPlatform("ground", width-(width/4), height-40, width/4, 40);
    
    // the ground now has an unjumpable gap:
    addGround("ground", 0, height-48, width/4, height);
    addGround("ground", width-(width/4), height-48, width, height);
    
    // Add some other static platforms
    //addStaticPlatform(0, height-100, 300, 100);
  }
  
  // Add all level platforms given a rectangles array
  void addDynamicPlatforms(ArrayList<StageElement> platformsArray) {
    for (StageElement stageElement : platformsArray) {
      addDynamicPlatform(stageElement.rect.x, stageElement.rect.y, stageElement.rect.width, stageElement.rect.height);
      
      if (stageElement.type == GREEN) {
        //BanzaiBill banzai = new BanzaiBill(stageElement.rect.x, stageElement.rect.y);
        //addInteractor(banzai);
        
        Muncher muncher = new Muncher(stageElement.rect.x+0.5*stageElement.rect.width, stageElement.rect.y-8);
        addInteractor(muncher);
      }
    }
  }
  
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
   
  Pipe addPipe(float x, float y) {
    Pipe p = new Pipe(x, y);
    addBoundedInteractor(p);
    addForegroundSprite(p.head);
    addForegroundSprite(p.body);
    addTrigger(p.trigger);
    return p;
  }

  // places a single tube with all the boundaries and behaviours
  /*void addTube(float x, float y, TeleportTrigger teleporter) {
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
  }*/
}

//////////////////
// Player Class
//////////////////

class Mario extends Player {

  int score = 0;
  float speed = 2;
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
    SoundManager.load(dead, "audio/Dead-mario.mp3");
  
    // jumping state
    State jumping = new State("jumping", "graphics/mario/small/Jumping-mario.gif");
    jumping.setDuration(15);
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
  }
  
  void resurrect() {
    removeActor();
    resetGame();
    //setPosition(initX, initY);
    //setCurrentState("idle");
    //isDying = false;
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
      addImpulse(0, -35);
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
      /*if (boundaries.size()>0) {
        for(Boundary b: boundaries) {
          if(b instanceof PipeBoundary) {
            ((PipeBoundary)b).trigger(this);
          }
        }
      }*/
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

