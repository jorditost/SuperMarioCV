ArrayList<StageElement> scaleStageElementsArray(ArrayList<StageElement> array, float factor) {
  for (StageElement stageElement : array) {
    stageElement.rect.x      *= factor;
    stageElement.rect.y      *= factor;
    stageElement.rect.width  *= factor;
    stageElement.rect.height *= factor;
  }
  return array;
}

ArrayList<Rectangle> scaleRectanglesArray(ArrayList<Rectangle> array, float factor) {
  for (Rectangle r : array) {
    r.x      *= factor;
    r.y      *= factor;
    r.width  *= factor;
    r.height *= factor;
  }
  return array;
}
