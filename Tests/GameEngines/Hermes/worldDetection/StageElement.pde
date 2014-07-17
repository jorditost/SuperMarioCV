/**
 * StageElement Class
 * 
 * @Author: Jordi Tost
 * @Author URI: jorditost.com
 *
 * Fachhochschule Potsdam Interfacedesign, 2013-2014
 */
 
//import java.awt.Rectangle;

static int NONE            = 0;
static int RED             = 1;
static int GREEN           = 2;
static int BLUE            = 3;
static int BLACK           = 4;

class StageElement {
  
  int type;
  Rectangle rect;
  
  StageElement() {
    rect = new Rectangle();
    type = NONE;
  }
  
  StageElement(Rectangle theRect, int theType) {
    rect = theRect;
    type = theType;
  }
  
  public Object clone() { 
     StageElement tmp = new StageElement(); 
     tmp.type = type;
     tmp.rect = rect;
     //tmp.rect = (Rectangle)(rect.clone());
     return tmp; 
  } 
}
