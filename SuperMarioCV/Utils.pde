ArrayList<StageElement> scaleStageElementsArray(ArrayList<StageElement> array, float factor) {
  
  // We have to clone the stage elements so as not to modify original values from StageDetector
  
  ArrayList<StageElement> clonedArray = new ArrayList<StageElement>();
  
  for (StageElement stageElement : array) {
    
    StageElement clonedStageElement = (StageElement)(stageElement.clone());
    
    clonedStageElement.rect.x      *= factor;
    clonedStageElement.rect.y      *= factor;
    clonedStageElement.rect.width  *= factor;
    clonedStageElement.rect.height *= factor;
    
    clonedArray.add(clonedStageElement);
  }
  
  return clonedArray;
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
