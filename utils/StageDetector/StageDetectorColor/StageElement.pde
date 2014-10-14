/**
 * StageElement Class
 * 
 * @Author: Jordi Tost @jorditost
 * @Author URI: jorditost.com
 *
 * University of Applied Sciences Potsdam, 2014
 */
 
import java.awt.Rectangle;

static int NONE            = 0;
static int RED             = 1;
static int GREEN           = 2;
static int BLUE            = 3;
static int BLACK           = 4;

class StageElement {
  
  PApplet parent;
  
  int colorId;
  
  // Contour
  public Rectangle rect;
  private Contour contour;
  
  public StageElement() {
    rect = new Rectangle();
    colorId = NONE;
  }
  
  public void display() {
    
    //Rectangle r = contour.getBoundingBox();
    
    if (colorId == RED) {
      stroke(255, 0, 0);
      fill(255, 0, 0, 150);
    } else if (colorId == GREEN) {
      stroke(0, 255, 0);
      fill(0, 255, 0, 100);
    } else if (colorId == BLUE) {
      stroke(0, 0, 255);
      fill(0, 0, 255, 100);
    } else {
      stroke(255, 255, 0);
      fill(255, 255, 0, 150);
    }
      
    strokeWeight(1);
    rect(rect.x, rect.y, rect.width, rect.height);
  }
  
  public StageElement(Rectangle rect, int colorId) {
    this.rect = rect;
    this.colorId = colorId;
  }
  
  public Object clone() { 
     StageElement tmp = new StageElement(); 
     tmp.colorId = colorId;
     tmp.rect = rect;
     //tmp.rect = (Rectangle)(rect.clone());
     return tmp; 
  } 
}
