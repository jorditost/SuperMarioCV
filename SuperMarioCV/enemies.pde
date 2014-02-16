/**
 * This lets us define enemies as being part of
 * some universal class of things, as opposed to
 * non enemy NPCs (like yoshis or toadstools)
 */

abstract class MarioEnemy extends Interactor {
  MarioEnemy(String name) { super(name); } 
  MarioEnemy(String name, float x, float y) { super(name, x, y); } 
}

abstract class BoundedMarioEnemy extends BoundedInteractor {
  BoundedMarioEnemy(String name) { super(name); } 
  BoundedMarioEnemy(String name, float x, float y) { super(name, x, y); } 
}
 
/***************************************
 *                                     *
 *      INTERACTORS: BANZAI BILL       *
 *                                     *
 ***************************************/

/**
 * The big bullet that comes out of nowhere O_O
 */
class BanzaiBill extends MarioEnemy {

  /**
   * Relatively straight-forward constructor
   */
  BanzaiBill(float mx, float my) {
    super("Banzai Bill", 1, 1);
    setPosition(mx, my);
    setImpulse(-1, 0);
    setForces(0, 0);
    setAcceleration(0, 0);
    setupStates();
    // Banzai Bills do not care about boundaries or NPCs!
    setPlayerInteractionOnly(true);
    persistent = false;
  }

  /**
   * Banzai bill flies with great purpose.
   */
  void setupStates() {
    State flying = new State("flying", "graphics/enemies/Banzai-bill.gif");
    SoundManager.load(flying, "audio/Banzai.mp3");
    addState(flying);
    setCurrentState("flying");
    SoundManager.play(flying);
  }

  /**
   * What happens when we touch another actor?
   */
  /*void overlapOccurredWith(Actor other, float[] direction) {
    if (other instanceof Mario) {
      Mario m = (Mario) other;
      m.hit();
    }
  }*/
  
  /**
   * Nothing happens at the moment
   */
  void hit() {}
}

/**
 * The small bullet that comes out of nowhere O_O
 */
class BanzaiBullet extends MarioEnemy {

  /**
   * Relatively straight-forward constructor
   */
  BanzaiBullet(float mx, float my) {
    super("Banzai Bullet", 1, 1);
    setPosition(mx, my+8);
    setImpulse(-3, 0);
    setForces(0, 0);
    setAcceleration(0, 0);
    setupStates();
    // Banzai Bills do not care about boundaries or NPCs!
    setPlayerInteractionOnly(true);
    persistent = false;
  }

  /**
   * Banzai bill flies with great purpose.
   */
  void setupStates() {
    State flying = new State("flying", "graphics/enemies/Banzai-bullet.gif");
    //SoundManager.load(flying, "audio/Banzai.mp3");
    addState(flying);
    setCurrentState("flying");
    //SoundManager.play(flying);
  }

  /**
   * What happens when we touch another actor?
   */
  /*void overlapOccurredWith(Actor other, float[] direction) {
    if (other instanceof Mario) {
      Mario m = (Mario) other;
      m.hit();
    }
  }*/
  
  /**
   * Nothing happens at the moment
   */
  void hit() {}
}

/***************************************
 *                                     *
 *      INTERACTORS: BONUS TARGET      *
 *                                     *
 ***************************************/
 
class BonusTarget extends MarioEnemy {
  
  ArrayList<HitListener> listeners = new ArrayList<HitListener>();
  void addListener(HitListener l) { if (!listeners.contains(l)) { listeners.add(l); }}
  void removeListener(HitListener l) { listeners.remove(l); }  
  
  float radial = 40;
  
  BonusTarget(float x, float y, float r) {
    super("Bonus Target");
    setPosition(x,y);
    radial = r;
    setupStates();
  }

  void setupStates() {
    State swirl = new State("swirl","graphics/assorted/Target.gif", 1, 4);
    // Set up a circle path using bezier curves.
    // Each curve segment lasts 15 frames.
    float d = radial, k = 0.55 * d;
    swirl.addPathCurve(0,-d,   k,-d,   d,-k,   d,0,  15,1);
    swirl.addPathCurve(d,0,     d,k,    k,d,   0,d,  15,1);
    swirl.addPathCurve(0,d,    -k,d,   -d,k,  -d,0,  15,1);
    swirl.addPathCurve(-d,0,  -d,-k,  -k,-d,  0,-d,  15,1);
    swirl.setLooping(true);
    swirl.setAnimationSpeed(0.5);
    addState(swirl);

    SoundManager.load("target hit", "audio/Squish.mp3");
    SoundManager.load("pipe appears", "audio/Powerup.mp3");
  }

  void setPathOffset(int offset) {
    getState("swirl").sprite.setPathOffset(offset);
  }

  // when a target is hit, we want to tell our bonus level about that.
  void pickedUp(Pickup pickup) {
    SoundManager.play("target hit");
    for(HitListener l: listeners) {
      l.targetHit();
    }
  }

  /**
   * What happens when we touch another actor?
   */
  void overlapOccurredWith(Actor other, float[] direction) {
    if (other instanceof Mario) {
      Mario m = (Mario) other;
      m.hit();
    }
  }
}

/**
 * necessary for counting targets shot down
 */
interface HitListener { void targetHit(); }


/***************************************
 *                                     *
 *      INTERACTORS: KOOPA             *
 *                                     *
 ***************************************/
 
/**
 * Our main enemy
 */
class Koopa extends MarioEnemy {

  Koopa(float x, float y) {
    super("Koopa Trooper");
    setStates();
    setForces(-0.25, DOWN_FORCE);    
    setImpulseCoefficients(DAMPENING+0.25, DAMPENING+0.25);
    setPosition(x,y);
  }
  
  /**
   * Set up our states
   */
  void setStates() {
    // walking state
    State walking = new State("idle", "graphics/enemies/Red-koopa-walking.gif", 1, 2);
    walking.setAnimationSpeed(0.12);
    SoundManager.load(walking, "audio/Squish.mp3");
    addState(walking);
    
    // if we get squished, we first get naked...
    State naked = new State("naked", "graphics/enemies/Naked-koopa-walking.gif", 1, 2);
    naked.setAnimationSpeed(0.12);
    SoundManager.load(naked, "audio/Squish.mp3");
    addState(naked);
    
    setCurrentState("idle");
  }
  
  /**
   * when we hit a vertical wall, we want our
   * koopa to reverse direction
   */
  void gotBlocked(Boundary b, float[] intersection, float[] original) {
    if (b.x==b.xw) {
      ix = -ix;
      fx = -fx;
      setHorizontalFlip(fx > 0);
    }
  }
  
  void hit() {
    SoundManager.play(active);

    // do we have our shell? Then we only get half-squished.
    if (active.name != "naked") {
      setCurrentState("naked");
      return;
    }
    
    // no shell... this koopa is toast.
    removeActor();
  }
}

/*****

class Koopa extends Interactor {
  // we construct a Koopa trooper pretty much the same way we did Mario:
  Koopa(float x, float y) {
    super("Koopa Trooper");
    setStates();
    //setForces(-0.05, DOWN_FORCE);
    setForces(-0.25, DOWN_FORCE);    
    setImpulseCoefficients(DAMPENING, DAMPENING);
    setPosition(x,y);
  }
  
  // And we use states.
  void setStates() {
    // walking state
    State walking = new State("idle", "graphics/enemies/Red-koopa-walking.gif", 1, 2);
    walking.setAnimationSpeed(0.12);
    addState(walking);
    
    // if we get squished, we first lose our shell.
    State noshell = new State("noshell", "graphics/enemies/Naked-koopa-walking.gif", 1, 2);
    noshell.setAnimationSpeed(0.12);
    addState(noshell);
    
    setCurrentState("idle");
  }
  
  void gotBlocked(Boundary b, float[] intersection) {
    
    // is the boundary vertical?
    if (b.x == b.xw) {
      // yes it is. Reverse direction!
      fx = -fx;
      setHorizontalFlip(fx > 0);
    }
  }
  
  void squish() {
    // do we have our shell? Then we only get half-squished.
    if (active.name != "noshell") {
      setCurrentState("noshell");
      return;
    }
    // no shell... this koopa is toast.
    removeActor();
  }
}

******/


/***************************************
 *                                     *
 *      INTERACTORS: MUNCHER PLANT     *
 *                                     *
 ***************************************/

/**
 * The muncher plant. To touch it is to lose.
 */
class Muncher extends BoundedMarioEnemy {
  
  //int t = millis();
  //int period = 2000;
  
  Muncher(float x, float y) {
    super("Muncher");
    setPosition(x,y);
    setupStates();
    addBoundary(new Boundary(x-width/2,y+2-height/2,x+width/2,y+2-height/2), true);
  }

  void setupStates() {
    //State munch = new State("munch", "graphics/enemies/Blume2.png", 1, 2);
    State munch = new State("munch", "graphics/enemies/Muncher.gif", 1, 2);
    munch.setAnimationSpeed(0.20);
    addState(munch);
    
    // if we get squished, we first get naked...
    //State hidden = new State("munch", "graphics/enemies/Blume2.png", 1, 2);
    State hidden = new State("hidden", "graphics/enemies/Muncher.gif", 1, 2);
    hidden.setAnimationSpeed(0.20);
    addState(hidden);
    
    setCurrentState("munch");
  }

  void collisionOccured(Boundary boundary, Actor other, float[] correction) {
    
    
    if (other instanceof Mario) {
      ((Mario)other).hit();
    }
  }
}
