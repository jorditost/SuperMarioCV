ArrayList<Rectangle> scaleRectanglesArray(ArrayList<Rectangle> array, float factor) {
  for (Rectangle r : array) {
    r.x      *= factor;
    r.y      *= factor;
    r.width  *= factor;
    r.height *= factor;
  }
  return array;
}
