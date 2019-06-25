class CurrentBlockDisplay {
  /*
  The thumbnail of the current block
   It can be clicked on the change the texture of that block
   */
  float x, y, width, height, margin;

  public CurrentBlockDisplay () {
    x = 500;
    y = 50;
    width = 100;
    height = 100;
    margin = 5;
  }

  public CurrentBlockDisplay (float xi, float yi) {
    x = xi;
    y = yi;
    width = 100;
    height = 100;
    margin = 5;
  }

  void draw() {
    pushMatrix();
    pushStyle();
    fill(255);
    stroke(0);


    translate (x, y);

    pushStyle();
    strokeWeight(1);
    rect (0, 0, width, height);
    popStyle();

    if (selectedBlock != null) {
      pushMatrix();

      translate (width/2, margin);
      scale (min((width - margin*2) / (selectedBlock.getLength() + selectedBlock.getHeight()), (height - margin*2) / selectedBlock.getWidth()));
      translate (0, selectedBlock.getHeight());

      selectedBlock.draw();

      popMatrix();
    }
    popStyle();
    popMatrix();
  }

  void click(int xCheck, int yCheck) {
    if (selectedBlock != null && xCheck >= x && xCheck <= x + width && yCheck >= y && yCheck <= y + height) {
      if (yCheck < y + height/2) {
        selectedBlock.setTopTexture();
      } else {
        selectedBlock.setSideTexture();
      }
    }
  }
}

class PDFButton {
  /*
  The button to export to pdf
   */
  int x, y, width, height;

  public PDFButton(int xi, int yi, int widthi, int heighti) {
    x = xi;
    y = yi;
    width = widthi;
    height = heighti;
  }

  void draw() {
    pushStyle();
    fill(255);
    stroke(0);
    strokeWeight(1);
    rect (x, y, width, height);

    noStroke();
    fill(0);
    textAlign(CENTER, CENTER);
    text("Make PDF", x + width/2, y + height/2 - 1);

    popStyle();
  }

  void click(int xCheck, int yCheck) {
    if (xCheck >= x && xCheck <= x + width && yCheck >= y && yCheck <= y + height) {
      //makePDF(8.5, 11, "Test");
      selectOutput ("Save pdf", "makePDF");
    }
  }
}

class BlockPaletteElement {
  /*
  Palette elements keep a cube saved for easy duplication
   */
  float x, y, width, height, margin;
  Block paletteBlock;

  public BlockPaletteElement(float xi, float yi) {
    x = xi;
    y = yi;
    width = 100;
    height = 100;
    margin = 5;
  }

  public BlockPaletteElement(float xi, float yi, Block ci) {
    this(xi, yi);
    paletteBlock = ci.clone();
  }

  void setBlock(Block cNew) {
    if (cNew != null) {
      paletteBlock = cNew.clone();
    }
  }

  void draw() {
    pushMatrix();
    pushStyle();
    fill(255);
    stroke(0);


    translate (x, y);

    pushStyle();
    strokeWeight(1);
    rect (0, 0, width, height);
    popStyle();

    if (paletteBlock != null) {
      pushMatrix();

      translate (width/2, margin);
      scale (min((width - margin*2) / (paletteBlock.getLength() + paletteBlock.getHeight()), (height - margin*2) / paletteBlock.getWidth()));
      translate (0, paletteBlock.getHeight());

      paletteBlock.draw();

      popMatrix();
    }
    popStyle();
    popMatrix();
  }

  boolean click(int xCheck, int yCheck) {
    if (xCheck >= x && xCheck <= x + width && yCheck >= y && yCheck <= y + height) {
      if (mouseButton == LEFT) {
        //left click to select a copy of the palette block
        if (paletteBlock != null) {
          setSelectedBlock(paletteBlock.clone());
        }
      } else if (mouseButton == RIGHT && paletteBlock != null) {
        //right click to replace the palette block with the current block
        setBlock(selectedBlock);
        setSelectedBlock(null);
      }
      return true;
    }
    return false;
  }
}

class IntField {
  //Int fields are used to store the dimensions of the current cube
  float x, y, tWidth, tHeight;
  int value;
  boolean editing;
  String name;


  public IntField(float xi, float yi, float tWidthi, float tHeighti, String namei, int valuei) {
    x = xi;
    y = yi;
    tWidth = tWidthi;
    tHeight = tHeighti;
    name = namei;
    value = valuei;
  }

  void setValue(int valueNew) {
    value = valueNew;
  }

  int getValue() {
    return value;
  }

  void click(int xCheck, int yCheck) {
    if (mouseButton == LEFT) {
      if (xCheck >= x && yCheck >= y && xCheck <= x + tWidth && yCheck <= y + tHeight) {
        editing = true;
        if (selectedBlock == null) {
          selectedBlock = new Block (dimensions);
        }
      } else {
        editing = false;
      }
    }
  }

  int type() {

    if (editing) {
      if (key == BACKSPACE) {
        if (value % 1 == 0) {
          value = value / 10;
        }
      } else if ((key >= '0' && key <= '9')) {
        value = min(value * 10 + key - 48, 1000);
      }
    }
    return value;
  }

  void draw() {
    pushStyle();
    textAlign(RIGHT, CENTER);
    fill(0);
    text (name, x - 10, y + tHeight/2 -1);
    popStyle();

    pushStyle();
    fill(255);
    stroke(0);
    strokeWeight (editing ? 2 : 1);
    rect (x, y, tWidth, tHeight);
    fill (0);
    noStroke();
    text (value, x + 10, y + tHeight/2 - 1);
    popStyle();
  }
}
