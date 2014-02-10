/**
 * We must set the screen dimensions to something
 */
final int BLOCK = 16,
          screenWidth = 32*BLOCK,
          screenHeight = 27*BLOCK;

/**
 * Gravity consists of a uniform downforce,
 * and a gravitational acceleration
 */
float DOWN_FORCE = 2;
float ACCELERATION = 1.3;
float DAMPENING = 0.75;


/**
 * initializing means building an "empty"
 * level, which we'll 
 */
void initialize() {
  frameRate(30);
  reset();
}

void reset() {
  clearScreens();
  addScreen("MainLevel", new MainLevel(width, height));  
}

/**
 * Our "empty" level is a single layer
 * level, doing absolutely nothing.
 */
class MainLevel extends Level {
  MainLevel(float levelWidth, float levelHeight) {
    super(levelWidth, levelHeight);
    addLevelLayer("background layer", new MainBackgroundLayer(this));
    addLevelLayer("main layer", new MainLevelLayer(this));
    setViewBox(0,0,screenWidth,screenHeight);
  }
}

/**
 * Our main level layer has a background
 * color, and nothing else.
 */
class MainBackgroundLayer extends LevelLayer {
  Mario mario;
  MainBackgroundLayer(Level owner) {
    super(owner, owner.width, owner.height, 0,0, 0.75,0.75);
    setBackgroundColor(color(0, 100, 190));
    addBackgroundSprite(new TilingSprite(new Sprite("graphics/backgrounds/sky_2.gif"),0,0,width,height));
  }
}


/**
 * Our main level layer has a background
 * color, and nothing else.
 */
class MainLevelLayer extends LevelLayer {
  Mario mario;
  
  MainLevelLayer(Level owner) {
    super(owner);
    addBackgroundSprite(new TilingSprite(new Sprite("graphics/backgrounds/sky.gif"),0,0,width,height));

    // set up Mario!
    mario = new Mario();
    mario.setPosition(32, height-64);
    addPlayer(mario);

    // we don't want mario to walk off the level,
    // so let's add some side walls
    addBoundary(new Boundary(-1,0, -1,height));
    addBoundary(new Boundary(width+1,height, width+1,0));

    // add general ground, with an unjumpable gap!
    addGround("ground", -32,height-48, width/2-96,height);
    addGround("ground", width/2 + 49,height-48, width+32,height);

    // then, add two teleporters on either side of the gap
    Pipe t1 = addPipe(width/4-16, height-48);
    Pipe t2 = addPipe(3*width/4-64, height-48);

    // and link them together
    t1.teleportTo(t2);
    t2.teleportTo(t1);
    
    //showBoundaries = true;
    //showTriggers = true;
  }

  void draw() {
    super.draw();
    if(mario.y>height+64) { 
      mario.setPosition(32,height-64); 
    }
  }

  /**
   * Add a teleporter to the scene
   */
  Pipe addPipe(float x, float y) {
    Pipe p = new Pipe(x, y);
    addBoundedInteractor(p);
    addForegroundSprite(p.head);
    addForegroundSprite(p.body);
    addTrigger(p.trigger);
    return p;
  }
  
  /**
   * Add some ground.
   */
  void addGround(String tileset, float x1, float y1, float x2, float y2) {
    TilingSprite groundline = new TilingSprite(new Sprite("graphics/backgrounds/"+tileset+"-top.gif"), x1,y1,x2,y1+16);
    addBackgroundSprite(groundline);
    TilingSprite groundfiller = new TilingSprite(new Sprite("graphics/backgrounds/"+tileset+"-filler.gif"), x1,y1+16,x2,y2);
    addBackgroundSprite(groundfiller);
    addBoundary(new Boundary(x1,y1,x2,y1));
  }
}

/**
 * Our dapper hero
 */
class Mario extends Player {
  
  int score = 0;
  float speed = 2;

  Mario() {
    super("Mario");
    setStates();
    handleKey('W');
    handleKey('A');
    handleKey('S');
    handleKey('D');
    setImpulseCoefficients(DAMPENING, DAMPENING);
    setForces(0, DOWN_FORCE);
    setAcceleration(0, ACCELERATION);
  }

  // make sure all states are center/bottom anchored
  void addState(State st) {
    st.sprite.anchor(CENTER, BOTTOM);
    super.addState(st);
  }  
  
  /**
   * Set up our states
   */
  void setStates() {
    // idling state
    addState(new State("idle", "graphics/mario/small/Standing-mario.gif"));

    // crouching state
    addState(new State("crouching", "graphics/mario/small/Crouching-mario.gif"));

    // running state
    addState(new State("running", "graphics/mario/small/Running-mario.gif", 1, 4));
    
    // jumping state
    State jumping = new State("jumping", "graphics/mario/small/Jumping-mario.gif");
    jumping.setDuration(15);
    addState(jumping);
    SoundManager.load(jumping, "audio/Jump.mp3");

    // crouchjumping state
    State crouchjumping = new State("crouchjumping", "graphics/mario/small/Crouching-mario.gif");
    crouchjumping.setDuration(15);
    addState(crouchjumping);
    SoundManager.load(crouchjumping, "audio/Jump.mp3");

    // default: just stand around doing nothing
    setCurrentState("idle");
  }

  /**
   * When 'fixed frame count' animations end
   * such as the jump animation, what should we do?
   */
  void handleStateFinished(State which) {
    setCurrentState("idle");
  }

  void handleInput() {
    // what do we "do"? (i.e. movement wise)
    if (active.name!="crouching" && (isKeyDown('A') || isKeyDown('D'))) {
      if (isKeyDown('A')) {
        setHorizontalFlip(true);
        addImpulse(-speed, 0);
      }
      if (isKeyDown('D')) {
        setHorizontalFlip(false);
        addImpulse(speed, 0);
      }
    }

    // if the jump key is pressed, and we're standing on something, let's jump! 
    if (active.mayChange() && isKeyDown('W') && boundaries.size()>0) {
      ignore('W');
      addImpulse(0, -35);
      if (active.name!="crouching") { setCurrentState("jumping"); }
      else { setCurrentState("crouchjumping"); }
      SoundManager.play(active);
    }

    // if we're not jumping, but left or right is pressed,
    // make sure we're using the "running" state.
    if (isKeyDown('S')) {
      if (active.name=="jumping") { setCurrentState("crouchjumping"); }
      else { setCurrentState("crouching"); }
    }

    if (active.mayChange()) {
      if (active.name!="crouching" && (isKeyDown('A') || isKeyDown('D'))) {
        setCurrentState("running");
      }
      else if (noKeysDown()) { setCurrentState("idle"); }
    }
  }
}

/**
 * 
 */
class Pipe extends BoundedInteractor {
  Lid lid;
  Sprite head, body;
  TeleportTrigger trigger;
  
  Pipe(float x, float y) {
    super("Teleporter");
    setPosition(x,y);
    // set up the sprite graphics
    head = new Sprite("graphics/assorted/Pipe-head.gif");
    head.align(LEFT,BOTTOM);
    head.setPosition(x,y-16);
    body = new Sprite("graphics/assorted/Pipe-body.gif");
    body.align(LEFT,BOTTOM);
    body.setPosition(x,y);
    
    // add the five boundaries, of which the top is a special "lid" boundary
    lid = new Lid(x,y-48, x+32,y-48);
    addBoundary(lid);
    addBoundary(new Boundary(x+32,y-48, x+32,y));
    addBoundary(new Boundary(x+32,y, x,y));
    addBoundary(new Boundary(x,y, x,y-48));

    // a hidden boundery inside the pipe, so we don't fall through
    addBoundary(new Boundary(x,y-8, x+32,y-8));

    // and set up our teleport trigger
    trigger = new TeleportTrigger(x+2,y-10,28,2);
    trigger.setLid(lid);
  }

  void teleportTo(Pipe other) {
    trigger.setDestination(other.x+16, other.y-24);
  }
  
  void collisionOccured(Boundary boundary, Actor other, float[] correction) {}
}

/**
 *
 */
class Lid extends Boundary {
  Lid(float x1, float y1, float x2, float y2) {
    super(x1,y1,x2,y2);
  }

  // when we teleport an actor, it should get a zero-impulse
  float[] STATIONARY = {0,0};
   
  // keeps Processing.js happy
  float[] redirectForce(float fx, float fy) {
    return super.redirectForce(fx,fy);
  }

  // teleport based on what the actor is doing
  float[] redirectForce(Actor a, float fx, float fy) {
    if(a.active.name=="crouching") {
      disable();
    }
    return super.redirectForce(a,fx,fy);
  }
}

class TeleportTrigger extends Trigger {
  Lid lid;
  float teleport_x, teleport_y;
  
  TeleportTrigger(float x, float y, float w, float h) {
    super("Teleporter",x,y,w,h);
    SoundManager.load(this, "audio/Pipe.mp3");
  }
  
  void setLid(Lid l) { lid = l; }
  
  void setDestination(float x, float y) {
    teleport_x = x;
    teleport_y = y;
  }
  
  void run(LevelLayer level, Actor actor, float[] intersection) {
    lid.enable();
    actor.setPosition(teleport_x,teleport_y);
    actor.setImpulse(0,-30);
    SoundManager.play(this);
  }
}
