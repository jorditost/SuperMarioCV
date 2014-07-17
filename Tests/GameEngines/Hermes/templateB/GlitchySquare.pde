/**
* An immobile flashing square --- DANGEROUS 
*/
class GlitchySquare extends Being {
    static final int WIDTH = 50;
    static final int HEIGHT = 50;
    static final int SHAKE_STEP = 10;
    color _c;

    GlitchySquare(int x, int y) {
        super(new Rectangle(x, y, WIDTH, HEIGHT));
        //Add your constructor info here
        //pickColor();
    }

    public void update() {
        //pickColor();
        _position.x += round(random(SHAKE_STEP * 2)) - SHAKE_STEP;
    }

    public void draw() {
        fill(_c);
        noStroke();
        _shape.draw();
    }
    
    public void setColor(color c) {
      _c = c;
    }
}
