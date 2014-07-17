/**
 * Template World
 * You'll need to add stuff to setup().
 */
class TemplateWorld extends World {
  
  static final int SQUARE_NUM = 10;
  TemplateWorld(int portIn, int portOut) {
    super(portIn, portOut);
  }

  void setup() {
    //IMPORTANT: put all other setup hereterBeing(TemplateBeing);
    for (int i = 0; i < SQUARE_NUM; i++) {
        int x = (int) random(WINDOW_WIDTH - 50);
        int y = (int) random(WINDOW_HEIGHT - 50);
        register(new GlitchySquare(x, y));
    }
  }
  
  void draw() {
    background(0);
    super.draw();
  }
}

