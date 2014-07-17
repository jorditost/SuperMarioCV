/**
 * When two GlitchySquares collide,
 * draw a border around them
 */
class SquareCollider extends Collider<GlitchySquare, GlitchySquare> {
    SquareCollider() {
        super();
        //Add your constructor info here
    }

    void handle(GlitchySquare being1, GlitchySquare being2) {
        being1.drawStroke();
        being2.drawStroke();
    }
}
