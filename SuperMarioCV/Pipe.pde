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
