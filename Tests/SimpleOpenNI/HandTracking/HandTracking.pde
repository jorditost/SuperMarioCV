// This sketch needs SimpleOpenNI v0.24

import SimpleOpenNI.*;
SimpleOpenNI kinect;

ArrayList<PVector> handPositions;

PVector currentHand;
PVector previousHand;

void setup() {
  size(640, 480);
  
  kinect = new SimpleOpenNI(this);
  kinect.setMirror(true);
  
  // Enable depthMap generation
  kinect.enableDepth();
  // Enable hands + gesture generation
  kinect.enableGesture();
  kinect.enableHands();
  
  kinect.addGesture("RaiseHand");
  handPositions = new ArrayList();
  
  stroke(255, 0, 0);
  strokeWeight(2);
}

void draw() {
  kinect.update();
  image(kinect.depthImage(), 0, 0);
  
  for (int i = 1; i < handPositions.size(); i++) {
    currentHand = handPositions.get(i);
    previousHand = handPositions.get(i-1);
    line(previousHand.x, previousHand.y, currentHand.x, currentHand.y);
  }
}

// ------------------------------------------

/*
  Hand Events
  ==============
       
  Our hand-tracking callbacks will take it from here.
*/

// This function gets called when we first begin tracking the user's hand
void onCreateHands(int handId, PVector position, float time) {
  println("++++ onCreateHands - handId: " + handId);
  kinect.convertRealWorldToProjective(position, position);
  handPositions.add(position);
}

// This function gets called over and over again for the duration of the time
// that we're tracking
void onUpdateHands(int handId, PVector position, float time) {
  println(">>>> onUpdateHands - handId: " + handId);
  kinect.convertRealWorldToProjective(position, position);
  handPositions.add(position);
}

// This function gets called once when we lose track of the user's hand because
// it's gone of of frame or been obscured by something else in the scene.
void onDestroyHands(int handId, float time) {
  println("---- onDestroyHands - handId: " + handId);
  handPositions.clear();
  kinect.addGesture("RaiseHand");
}

// ------------------------------------------

/*
  Gesture Events
  =================

  The onRecognizeGesture function will be called whenever the user performs a 
  gesture that we've told OpenNI to watch out for. In our case, that will only 
  be RaiseHands.

  When this gesture occurs, we have two steps to take:

    1. We want to tell OpenNI to start tracking the hand it's found.
       The third argument that gets passed to onRecognizeGesture is a PVector
       holding the current position of the hand. This is exactly the data that
       we need to kick off the hand tracking process. We do that by calling
       kinect.startTrackingHands(endPosition). This tells OpenNI to start
       looking for a hand at the location indicated by endPosition.
    2. Since we know that's just where the user's hand is located, this will
       work perfectly and we'll kick off hand tracking successfully. Once this
       is done, we can stop searching for the hand. We don't want to acciden-
       tally catch another RaiseHand gesture and reset our hand tracking process
       by calling startTrackingHands again. To avoid this, we call
       kinect.removeGesture("RaiseHand"). This tells OpenNI to stop looking for
       the raise-hands gesture.
*/

void onRecognizeGesture(String strGesture,
                        PVector idPosition,
                        PVector endPosition)
{
  kinect.startTrackingHands(endPosition);
  kinect.removeGesture("RaiseHand");
}








