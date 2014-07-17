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
        pickColor();
        //Add your constructor info here
    }

    public void update() {
        pickColor();
        _position.x += round(random(SHAKE_STEP * 2)) - SHAKE_STEP;
    }

    public void draw() {
        fill(_c);
        noStroke();
        _shape.draw();
    }

    private void pickColor() {
        _c = color(int(random(256)), int(random(256)), int(random(256)));
    }
}
