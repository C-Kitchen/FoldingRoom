import java.util.*;
import processing.pdf.*;
import java.util.function.*;

Edge[] wallEdges;
Texture[] wallTextures;
Texture floorTexture;
DrawBlock testDrawingIterator = new DrawBlock();//**testing a new feature

Edge selectedEdge;
Block selectedBlock;
int paletteX, paletteY, sidebarWidth, viewX, viewY, panX, panY, adjustedMouseX, adjustedMouseY, roomWidth, roomHeight, wallHeight, margin, placeholderTextureWidth, placeholderTextureHeight;
float zoom, extraWall;

EdgeDistance bestEdgeSoFar, testingEdge;

IntField[] dimensions; //dimensions currently entered in the fields for length, width, and height
boolean pan, panStarted, shift;
LinkedList<Block> extraBlocks; //block that aren't placed properly in the scene
PDFButton pdfButton;
Texture placeholderTexture;

CurrentBlockDisplay currentBlockDisplay;
BlockPaletteElement[] palette;

int[] mountain, valley; //these are the patterns for dashed lines

void loadImage(File textureImage) {
  /*
  This method is called by selectInput, which gets a file from the user
   Before this method is called, set the texture you want to set equal to placeholderTexture
   You can't change it directly because of threading
   */
  if (placeholderTexture != null && textureImage != null) {
    placeholderTexture.setImage(loadImage(textureImage.getAbsolutePath()));
    placeholderTexture.resize (placeholderTextureWidth, placeholderTextureHeight);
  }
  placeholderTexture = null;
}

class Texture {
  /*
  Basically just a wrapper class for PImage
   It keeps 2 copies of the texture, one at full resolution (img), and one at the desired resolution (display)
   */
  private PImage img, display;

  public Texture() {
  }

  public Texture (PImage imgi) {
    img = imgi;
    if (img != null) {
      display = img.copy();
    } else {
      display = null;
    }
  }

  private Texture (PImage imgi, PImage displayi) {
    img = imgi;
    display = displayi;
  }

  void setImage (PImage i) {
    img = i;
    if (img != null) {
      display = img.copy();
    } else {
      display = null;
    }
  }

  Texture clone() {
    if (img != null) {
      return new Texture (img.copy(), display.copy());
    } else {
      return new Texture();
    }
  }

  void resize(int w, int h) {
    if (img != null) {
      display = img.copy();
      if (display != null) {
        display.resize(w, h);
      }
    }
  }

  void draw(float x, float y) {

    if (img != null) {
      try{
      pushMatrix();
      translate (x, y);
      image (display, 0, 0);
      popMatrix();
      } catch (Exception e){
      }
    }
  }

  void draw(float x, float y, PGraphics pdf) {

    if (img != null) {
      pdf.pushMatrix();
      pdf.translate (x, y);
      pdf.image (display, 0, 0);
      pdf.popMatrix();
    }
  }
}


void setSelectedBlock(Block newSelection) {
  /*
  This is the method by which a new block is selected
   It makes sure the fields where you enter the dimension start with the proper values
   */
  selectedBlock = newSelection;
  if (selectedBlock != null) {
    int[] temp = selectedBlock.getDimensions();
    for (int i = 0; i < dimensions.length; i++) {
      dimensions[i].setValue(temp[i]);
    }
  }
}

void makePDF(File pdfOutput) {
  /*
  Makes a pdf of the room and the properly placed blocks
   Need to set it up to use selectOutput **
   */
  String filename = pdfOutput.getAbsolutePath();
  if (!(filename.substring(filename.length() - 4)).equals(".pdf")) {//string comparison
    filename = filename + ".pdf";
  }
  PGraphics pdf = createGraphics((int) (300 * 8.5), (int) (300 * 11), PDF, filename);
  pdf.beginDraw();
  pdf.background(255);
  drawWalls(pdf);
  for (int i = 0; i < wallEdges.length; i++) {
    wallEdges[i].draw(pdf);
  }
  pdf.dispose();
  pdf.endDraw();
}

void cutStyle() {
  /*
   Changes the style for drawing the cutting lines
   Currently this means thick red lines
   */
  strokeWeight(3);
  stroke (255, 0, 0);
  strokeCap(PROJECT);
  noFill();
}

void cutStyle(PGraphics pdf) {
  /*
  This method sets the style for the cutting lines in the pdf
   It's the same as the display, a thick red line.
   */
  pdf.strokeWeight(3);
  pdf.stroke (255, 0, 0);
  pdf.strokeCap(PROJECT);
  pdf.noFill();
}

float limit (float value, float minimum, float maximum) {
  return max(min(value, maximum), minimum);
}

public float distance (float x1, float y1, float x2, float y2) {
  /*
  Calculates the distance between 2 points
   */
  return (float) Math.sqrt((y2 - y1) * (y2 - y1) + (x2 - x1) * (x2 - x1));
}

void dashedLine (float x1, float y1, float x2, float y2, int[] dash) {
  /*
  Draws a dashed line (alternating black and white) between points x1, y1 and x2, y2
   The alternating dashes and gaps get their values from the dash array
   The dash or gap of length dash[0] is centered on the line
   */

  pushStyle();
  strokeCap(SQUARE);

  if (dash.length == 0) {//if the array is empty, just draw a full line
    stroke(0);
    line (x1, y1, x2, y2);
  } else {

    float totalDistance = distance (x1, y1, x2, y2);
    float dashDistance = 0;
    for (int i = 0; i < dash.length; i++) {

      dashDistance += dash[i];
    }
    float currentDistance = (totalDistance/2 - dash[0]/2) % dashDistance - dashDistance;
    int i = 0;
    boolean black = true;
    float smallerX = min(x1, x2);
    float biggerX = max(x1, x2);
    float smallerY = min(y1, y2);
    float biggerY = max(y1, y2);

    while (currentDistance < totalDistance) {
      stroke(black ? 0 : 255);
      line (limit(map (currentDistance, 0, totalDistance, x1, x2), smallerX, biggerX), limit(map (currentDistance, 0, totalDistance, y1, y2), smallerY, biggerY), limit(map (currentDistance + dash[i], 0, totalDistance, x1, x2), smallerX, biggerX), limit(map (currentDistance + dash[i], 0, totalDistance, y1, y2), smallerY, biggerY));

      currentDistance += dash[i];
      i = (i + 1) % dash.length;
      black = !black;
    }
  }
  popStyle();
}
void dashedLine (float x1, float y1, float x2, float y2, int[] dash, PGraphics pdf) {
  /*
  Draws a dashed line (alternating black and white) between points x1, y1 and x2, y2 to the pdf
   The alternating dashes and gaps get their values from the dash array
   The dash or gap of length dash[0] is centered on the line
   */
  pdf.pushStyle();
  pdf.strokeCap(SQUARE);

  if (dash.length == 0) {
    pdf.stroke(0);
    pdf.line (x1, y1, x2, y2);
  } else {

    float totalDistance = distance (x1, y1, x2, y2);
    float dashDistance = 0;
    for (int i = 0; i < dash.length; i++) {
      dashDistance += dash[i];
    }
    float currentDistance = (totalDistance/2 - dash[0]/2) % dashDistance - dashDistance; //sets the current distance back enough to get the line centered
    int i = 0;
    boolean black = true;
    float smallerX = min(x1, x2);
    float biggerX = max(x1, x2);
    float smallerY = min(y1, y2);
    float biggerY = max(y1, y2);

    while (currentDistance < totalDistance) {
      pdf.stroke(black ? 0 : 255);
      pdf.line (limit(map(currentDistance, 0, totalDistance, x1, x2), smallerX, biggerX), limit(map (currentDistance, 0, totalDistance, y1, y2), smallerY, biggerY), limit(map (currentDistance + dash[i], 0, totalDistance, x1, x2), smallerX, biggerX), limit(map (currentDistance + dash[i], 0, totalDistance, y1, y2), smallerY, biggerY));

      currentDistance += dash[i];
      i = (i + 1) % dash.length;
      black = !black;
    }
  }
  pdf.popStyle();
}

void drawWalls() {
  /*
  draws the outline of the walls 
   */
  pushMatrix();
  translate(wallHeight + margin, wallHeight * extraWall + margin);

  wallTextures[0].draw(0, -wallHeight);
  wallTextures[1].draw(roomWidth, 0);
  wallTextures[2].draw(0, roomHeight);
  wallTextures[3].draw(-wallHeight, 0);
  floorTexture.draw(0, 0);


  pushStyle();
  stroke(0);

  dashedLine (0, -wallHeight, roomWidth, -wallHeight, mountain);
  dashedLine (0, roomHeight + wallHeight, roomWidth, roomHeight + wallHeight, mountain);

  dashedLine (-wallHeight, 0, 0, 0, valley);
  dashedLine (roomWidth, 0, roomWidth + wallHeight, 0, valley);
  dashedLine (-wallHeight, roomHeight, 0, roomHeight, valley);
  dashedLine (roomWidth, roomHeight, roomWidth+wallHeight, roomHeight, valley);
  popStyle();

  pushStyle();
  cutStyle();

  beginShape();
  vertex (0, 0); 
  vertex (0, -wallHeight * extraWall);
  vertex (roomWidth, -wallHeight * extraWall);
  vertex (roomWidth, 0);
  endShape();

  beginShape();
  vertex (0, roomHeight); 
  vertex (0, roomHeight + wallHeight * extraWall);
  vertex (roomWidth, roomHeight + wallHeight * extraWall);
  vertex (roomWidth, roomHeight);
  endShape();

  beginShape();
  vertex (0, -wallHeight); 
  vertex (-wallHeight, -wallHeight);
  vertex (-wallHeight, roomHeight + wallHeight);
  vertex (0, roomHeight + wallHeight);
  endShape();

  beginShape();
  vertex (roomWidth, -wallHeight); 
  vertex (roomWidth + wallHeight, -wallHeight);
  vertex (roomWidth + wallHeight, roomHeight + wallHeight);
  vertex (roomWidth, roomHeight + wallHeight);
  endShape();
  popStyle();

  popMatrix();
}

void drawWalls(PGraphics pdf) {
  /*
  draws the walls to the pdf
   */
  pdf.pushMatrix();
  pdf.translate(wallHeight + margin, wallHeight * extraWall + margin);

  wallTextures[0].draw(0, -wallHeight, pdf);
  wallTextures[1].draw(roomWidth, 0, pdf);
  wallTextures[2].draw(0, roomHeight, pdf);
  wallTextures[3].draw(-wallHeight, 0, pdf);
  floorTexture.draw(0, 0, pdf);

  pdf.pushStyle();
  pdf.stroke(0);

  dashedLine (0, -wallHeight, roomWidth, -wallHeight, mountain, pdf);
  dashedLine (0, roomHeight + wallHeight, roomWidth, roomHeight + wallHeight, mountain, pdf);

  dashedLine (-wallHeight, 0, 0, 0, valley, pdf);
  dashedLine (roomWidth, 0, roomWidth + wallHeight, 0, valley, pdf);
  dashedLine (-wallHeight, roomHeight, 0, roomHeight, valley, pdf);
  dashedLine (roomWidth, roomHeight, roomWidth+wallHeight, roomHeight, valley, pdf);
  pdf.popStyle();

  pdf.pushStyle();
  cutStyle(pdf);

  pdf.beginShape();
  pdf.vertex (0, 0); 
  pdf.vertex (0, -wallHeight * extraWall);
  pdf.vertex (roomWidth, -wallHeight * extraWall);
  pdf.vertex (roomWidth, 0);
  pdf.endShape();

  pdf.beginShape();
  pdf.vertex (0, roomHeight); 
  pdf.vertex (0, roomHeight + wallHeight * extraWall);
  pdf.vertex (roomWidth, roomHeight + wallHeight * extraWall);
  pdf.vertex (roomWidth, roomHeight);
  pdf.endShape();

  pdf.beginShape();
  pdf.vertex (0, -wallHeight); 
  pdf.vertex (-wallHeight, -wallHeight);
  pdf.vertex (-wallHeight, roomHeight + wallHeight);
  pdf.vertex (0, roomHeight + wallHeight);
  pdf.endShape();

  pdf.beginShape();
  pdf.vertex (roomWidth, -wallHeight); 
  pdf.vertex (roomWidth + wallHeight, -wallHeight);
  pdf.vertex (roomWidth + wallHeight, roomHeight + wallHeight);
  pdf.vertex (roomWidth, roomHeight + wallHeight);
  pdf.endShape();
  pdf.popStyle();

  pdf.popMatrix();
}



void setup() {
  size(800, 600); 
  smooth();
  frameRate(30);
  textAlign (LEFT, CENTER);

  //sets default stroke
  strokeWeight(3);
  stroke(0);

  //starts centered on the page and zoomed out enough to see the whole thing
  zoom = (float) Math.pow(.75, 7);
  viewX = (int) (-8.5*150);
  viewY = -11*150;


  roomWidth = 1536;
  roomHeight = 1608;
  wallHeight = 400;
  margin = 100;
  extraWall = 1.8;

  wallEdges = new Edge[4];
  wallEdges[0] = new Edge (wallHeight + margin, (int) (wallHeight * extraWall) + margin, roomWidth, 0);
  wallEdges[1] = new Edge (roomWidth + wallHeight + margin, (int) (wallHeight * extraWall) + margin, roomHeight, PI/2);
  wallEdges[2] = new Edge (roomWidth + wallHeight + margin, roomHeight + (int) (wallHeight * extraWall) + margin, roomWidth, PI);
  wallEdges[3] = new Edge (wallHeight + margin, roomHeight + (int) (wallHeight * extraWall) + margin, roomHeight, PI*1.5);

  wallTextures = new Texture[4];
  for (int i = 0; i < wallTextures.length; i++) {
    wallTextures[i] = new Texture();
  }
  floorTexture = new Texture();

  sidebarWidth = 350;
  pdfButton = new PDFButton (width-130, height-40, 80, 20);

  dimensions = new IntField[3];
  for (int i = 0; i < dimensions.length; i++) {
    dimensions[i] = new IntField (width - 120, 50 + 30*i, 70, 22, i == 0 ? "Length" : i == 1 ? "Width" : "Height", 0);
  }

  currentBlockDisplay = new CurrentBlockDisplay();

  //make the dash patterns for mountain and valley folds
  int dashscale = 10;
  mountain = new int[]{1, 2, 5, 2, 5, 2};
  valley = new int[]{4, 3};

  for (int i = 0; i < mountain.length; i++) {
    mountain[i] *= dashscale;
  }
  for (int i = 0; i < valley.length; i++) {
    valley[i] *= dashscale;
  }

  //adjusted mouse positions are used when the mouse is in the scene area. This accounts for scaling and translation
  adjustedMouseX = 0;
  adjustedMouseY = 0;

  //initialize data structures
  extraBlocks = new LinkedList<Block>();
  palette = new BlockPaletteElement[6];

  //This is the palette where you can save blocks to duplicate later. It start out with some random block
  for (int i = 0; i < palette.length; i++) {
    palette[i] = new BlockPaletteElement((i % 2)*150, i / 2 * 120);
  }
  //bed
  palette[0].setBlock(new Block (960, 720, 288/2));
  (palette[0].paletteBlock).setTopTexture(loadImage("./Textures/bed_top.jpg"));
  (palette[0].paletteBlock).setSideTexture(loadImage("./Textures/bed_front.jpg"));
  
  //pillow
  palette[1].setBlock(new Block (240, 312, 60/2));
  (palette[1].paletteBlock).setTopTexture(loadImage("./Textures/pillow_top.jpg"));
  (palette[1].paletteBlock).setSideTexture(loadImage("./Textures/pillow_front.jpg"));
  
  //table1
  palette[2].setBlock(new Block (192, 240, 240/2));
  (palette[2].paletteBlock).setTopTexture(loadImage("./Textures/table1_top.jpg"));
  (palette[2].paletteBlock).setSideTexture(loadImage("./Textures/table1_front.jpg"));

  //table2
  palette[3].setBlock(new Block (180, 288, 288/2));
  (palette[3].paletteBlock).setTopTexture(loadImage("./Textures/table2_top.jpg"));
  (palette[3].paletteBlock).setSideTexture(loadImage("./Textures/table2_front.jpg"));
  
  //dresser
  palette[4].setBlock(new Block (216, 504, 384/2));
  (palette[4].paletteBlock).setTopTexture(loadImage("./Textures/dresser_top.jpg"));
  (palette[4].paletteBlock).setSideTexture(loadImage("./Textures/dresser_front.jpg"));
  
  palette[5].setBlock(new Block (250, 250, 150));

  //sets the coordinates for the palette
  paletteX = 500;
  paletteY = 200;

  //these booleans are used to navigate the scene
  pan = false;
  panStarted = false;
} 

void draw() {
  background(128);

  //move and zoom the "camera" for the scene area
  pushMatrix();
  translate ((width - sidebarWidth)/2 + (panStarted ? mouseX - panX : 0), height/2 + (panStarted ? mouseY - panY : 0));
  scale (zoom);
  translate (viewX, viewY);

  //draw the outline of the page
  pushStyle();
  strokeWeight(1/zoom);
  fill(255);
  stroke(0);
  rect(0, 0, 8.5 *300, 11 * 300);
  popStyle();

  //draw the walls
  drawWalls();

  //calculate the adjustsed mouse coordinates for the scene area
  adjustedMouseX = (int) ((mouseX-(width - sidebarWidth)/2)/zoom) - viewX;
  adjustedMouseY = (int) ((mouseY-height/2)/zoom) - viewY;

  //draw the original edges, which recursively will draw the complete scene
  for (int i = 0; i < wallEdges.length; i++) {
    wallEdges[i].draw();
  }

  //find the best edge to place the current block onto (it may be no edge, in which case it shows the block with a red tint)
  if (selectedBlock != null) {
    bestEdgeSoFar = null;

    for (int i = 0; i < wallEdges.length; i++) {
      //recursively test the edges and their children, setting the best edge, if any, to selectedEdge
      testingEdge = wallEdges[i].startGetBest(adjustedMouseX, adjustedMouseY, selectedBlock);
      if (bestEdgeSoFar == null) {
        bestEdgeSoFar = testingEdge;
      } else if (testingEdge != null) {
        if (bestEdgeSoFar.distance > testingEdge.distance) {
          fill(0);

          bestEdgeSoFar = testingEdge;
        }
      }
    }
    if (bestEdgeSoFar == null) {
      selectedEdge = null;
    } else {
      selectedEdge = bestEdgeSoFar.edge;
    }
  }


  //You can place non-printing block to save for later
  /*ListIterator extraBlockIterator = extraBlocks.listIterator();
  while (extraBlockIterator.hasNext()) {
    ((Block) extraBlockIterator.next()).drawOutOfPlace();
  }*/
  extraBlocks.forEach(testDrawingIterator);//**first test of using forEach instead of an iterator. Code will need more restructuring before this gets rolled out over the whole project
  

  //the selected block will either be placed in place on the edge or under the mouse if no edge looks good
  if (mouseX < width - sidebarWidth) {
    if (selectedBlock != null && selectedEdge != null) {
      selectedBlock.project(selectedEdge, bestEdgeSoFar.position);
    } else if (selectedBlock != null && !panStarted) {
      selectedBlock.x = (int) adjustedMouseX;
      selectedBlock.y = (int) adjustedMouseY;
      selectedBlock.drawOutOfPlace();
    }
  }
  popMatrix();
  //move the camera back to default position to draw the sidebar

  pushStyle();

  //draw the sidebar
  fill(255);
  stroke(0);
  strokeWeight(3);
  rect (width - sidebarWidth, 0, sidebarWidth, height);
  currentBlockDisplay.draw();

  //draw the fields to enter dimensions for the current block
  for (int i = 0; i < dimensions.length; i++) {
    dimensions[i].draw();
  }

  popStyle();

  //draw the block palette
  pushMatrix();
  translate(paletteX, paletteY);
  for (int j = 0; j < palette.length; j++) {
    palette[j].draw();
  }
  popMatrix();

  //draw the pdf export button
  pdfButton.draw();
}

void mousePressed(MouseEvent evt) {
  if (mouseX < width - sidebarWidth) { //mouse in scene area
    if (pan && mouseButton == LEFT && !panStarted) { //set the initial position for a pan
      panX = mouseX;
      panY = mouseY;
      panStarted = true;
    } else if (mouseButton == LEFT && selectedBlock != null) {
      //if a block is selected
      if (selectedEdge == null) {
        //if there's a good edge, attach the block to that edge
        extraBlocks.add(selectedBlock);
        setSelectedBlock (null);
      } else if (selectedEdge != null) {
        //if there's no good edge, just put the block in the unprintable block list and leave it in place
        selectedEdge.addBlock(selectedBlock);
        setSelectedBlock (null);
      }
    } else if (mouseButton == LEFT && selectedBlock == null) {
      //if there is no block selected, look through the extra block (descending so that you pick up the uppermost block if there's overlap)
      Iterator extraBlockIterator = extraBlocks.descendingIterator();
      Block temp;
      while (extraBlockIterator.hasNext()) {
        //temp is the block we're currently checking is under the mouse
        temp = (Block) extraBlockIterator.next();
        if (adjustedMouseX >= temp.x - temp.getWidth()/2 && adjustedMouseX <= temp.x + temp.getWidth()/2 && adjustedMouseY >= temp.y - temp.getHeight() && adjustedMouseY <= temp.y + temp.getLength()) {
          //if it's under the mouse, select it and remove it from the extra blocks
          setSelectedBlock (temp);
          extraBlockIterator.remove();
          break;
        }
      }
      if (selectedBlock == null) { //if we didn't find an extra block to pick up, check the blocks attached to edges
        for (int j = 0; j < wallEdges.length; j++) {
          setSelectedBlock (wallEdges[j].startFindBlock(adjustedMouseX, adjustedMouseY));
          if (selectedBlock != null) {
            break;
          }
        }
      }
      if (selectedBlock == null && evt.getCount() > 1) { //if we didn't find any blocks under the mouse
        boolean inroomX = adjustedMouseX > wallHeight + margin && adjustedMouseX < wallHeight + margin + roomWidth; //is the x coordinate of the mouse inside the room
        boolean inroomY = adjustedMouseY < wallHeight * extraWall + margin + roomHeight && adjustedMouseY > wallHeight * extraWall + margin; //is the y coordinate of the mouse inside the room
        if (inroomX) {
          placeholderTextureWidth = (int) roomWidth;
          if (inroomY) {
            //floor texture
            placeholderTexture = floorTexture;
            placeholderTextureHeight = (int)roomHeight;
            selectInput("Choose an image", "loadImage");
          } else if (adjustedMouseY < wallHeight * extraWall + margin && adjustedMouseY > wallHeight * (extraWall -1 ) + margin) {
            //top wall texture
            placeholderTexture = wallTextures[0];
            placeholderTextureHeight = (int)wallHeight;
            selectInput("Choose an image", "loadImage");
          } else if (adjustedMouseY < roomHeight + wallHeight * (extraWall + 1) + margin && adjustedMouseY > roomHeight + wallHeight * extraWall + margin) {
            //bottom wall texture
            placeholderTexture = wallTextures[2];
            placeholderTextureHeight = (int)wallHeight;
            selectInput("Choose an image", "loadImage");
          }
        } else if (inroomY) {
          if (adjustedMouseX > roomWidth + wallHeight + margin && adjustedMouseX < roomWidth + wallHeight * 2 + margin) {
            //right wall texture
            placeholderTexture = wallTextures[1];
            placeholderTextureWidth = (int) wallHeight;
            placeholderTextureHeight = (int) roomHeight;
            selectInput("Choose an image", "loadImage");
          } else if (adjustedMouseX > margin && adjustedMouseX < wallHeight + margin) {
            //left wall texture
            placeholderTexture = wallTextures[3];
            placeholderTextureWidth = (int) wallHeight;
            placeholderTextureHeight = (int) roomHeight;
            selectInput("Choose an image", "loadImage");
          }
        }
      }
    }
  } else { //mouse in sidebar
    for (int i = 0; i < palette.length; i++) {
      //check if you clicked on any of the palette elements, if so, don't bother checking the rest.
      if (palette[i].click(mouseX - paletteX, mouseY - paletteY)) {
        break;
      }
    }
    for (int i = 0; i < dimensions.length; i++) {
      //check if you clicked on any of the int fields for the dimensions
      dimensions[i].click(mouseX, mouseY);
    }
    if (mouseButton == LEFT) {
      //check the pdf button
      pdfButton.click(mouseX, mouseY);

      //check if you clicked on the current block display to change the texture
      currentBlockDisplay.click(mouseX, mouseY);
    }
  }
}

void mouseReleased() {
  //finish a pan when you release the mouse
  if (panStarted) {
    viewX += (mouseX - panX)/zoom;
    viewY += (mouseY - panY)/zoom;
  }
  panStarted = false;
}

void keyPressed() {
  if (key == '-') {
    //zoom out
    zoom *= .75;
  } else if (key == '=') {
    //zoom in
    zoom /= .75;
  } else if (key == ' ') {
    //start panning
    pan = true;
  } else if (keyCode == TAB) {
    //cycle through the int fields (shift tells it to go backwards)
    for (int i = 0; i < dimensions.length; i++) {
      if (dimensions[i].editing) {
        dimensions[i].editing = false;
        dimensions[(i + (shift ? 2 : 1)) % dimensions.length].editing = true;
        break;
      }
    }
  } else if (keyCode == SHIFT) {
    //check if shift is held so that it can cycle through int fields backwards if necessary
    shift = true;
  } else if (keyCode == DELETE) {
    //delete the selected block
    setSelectedBlock(null);
  }

  if (selectedBlock != null) {
    //check if you're editing any of the int fields and change their values based on what you type
    for (int i = 0; i < dimensions.length; i++) {
      selectedBlock.setDimension(i, dimensions[i].type());
    }
  }
}

void keyReleased() {
  if (key == ' ') {
    //stop panning when you let go of spacebar
    pan = false;
  } else if (keyCode == SHIFT) {
    //stop backwards cycling through int fields
    shift = false;
  }
}
