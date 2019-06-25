class Block {
  /*
  These are the blocks that make up the furniture of the scene
   */
  private int[] dimensions; //the dimensions of the block (length, width, height)
  int position, x, y; 
  Texture topTexture, sideTexture;
  boolean attachedToEdge;

  Edge top, bottom; //the tops and bottoms of blocks can have more blocks attached

  public Block(int lengthi, int widthi, int heighti) {
    this (new int[]{lengthi, widthi, heighti});
    position = 25;

    x = 0;
    y = 0;

    top = new Edge (-dimensions[1]/2, -dimensions[2], dimensions[1], 0);
    bottom = new Edge (-dimensions[1]/2, dimensions[0], dimensions[1], 0);
    topTexture = new Texture();
    sideTexture = new Texture();
  }

  public Block(IntField[] dimensionFields) {
    this (dimensionFields.length < 1 ? 100 : dimensionFields[0].getValue(), dimensionFields.length < 2 ? 100 : dimensionFields[1].getValue(), dimensionFields.length < 3 ? 100 : dimensionFields[2].getValue());
  }

  private Block(int[] dimensionsi) {
    if (dimensionsi.length == 3) {
      dimensions = dimensionsi;
    } else {
      dimensions = new int[]{200, 200, 100};
    }
    limitDimensions();
  }

  private Block (int[] dimensionsi, int positioni, int xi, int yi, Edge topi, Edge bottomi, Texture topTexturei, Texture sideTexturei) {
    this(dimensionsi);
    position = positioni;

    x = xi;
    y = yi;

    top = topi;
    bottom = bottomi;

    topTexture = topTexturei;
    sideTexture = sideTexturei;
  }

  Block clone() {
    return new Block (dimensions.clone(), position, x, y, top.clone(), bottom.clone(), topTexture.clone(), sideTexture.clone());
  }

  int[] getDimensions() {
    return dimensions;
  }

  void setDimensions(int[] a) {
    if (a.length == 3) {
      dimensions = a.clone();
    }
    resizeTopTexture();
    resizeSideTexture();
  }

  void setDimensions(IntField[] dimensionFields) {
    if (dimensionFields.length == 3) {
      for (int i = 0; i < dimensions.length; i++) {
        dimensions[i] = dimensionFields[i].getValue();
      }
    }
  }

  void limitDimensions() {
    for (int i = 0; i < dimensions.length; i++) {
      dimensions[i] = max(dimensions[i], 50);
    }
  }

  void setDimension(int i, int newValue) {
    dimensions[i] = newValue;
    limitDimensions();
    resizeTopTexture();
    resizeSideTexture();
    resetBottomEdge();
    resetTopEdge();
  }

  void resizeTopTexture() {
    topTexture.resize(dimensions[1], dimensions[0]);
  }

  void resizeSideTexture() {
    sideTexture.resize(dimensions[1], dimensions[2]);
  }

  void resetTopEdge() {
    top.startX = -dimensions[1]/2;
    top.startY = -dimensions[2];
    top.eLength = dimensions[1];
    top.eAngle = 0;
  }

  void resetBottomEdge() {
    bottom.startX = -dimensions[1]/2;
    bottom.startY = dimensions[0];
    bottom.eLength = dimensions[1];
    bottom.eAngle = 0;
  }

  void setPosition(int p) {
    position = p;
  }

  void project (Edge e, int newPosition) {
    e.temp = this;
    position = newPosition;
  }

  void setTopTexture(PImage i) {
    topTexture.setImage(i);
    resizeTopTexture();
  }

  void setSideTexture(PImage i) {
    sideTexture.setImage(i);
    resizeSideTexture();
  }

  void setTopTexture(String filename) {
    topTexture.setImage(loadImage(filename));
    resizeTopTexture();
  }

  void setSideTexture(String filename) {
    sideTexture.setImage(loadImage(filename));
    resizeSideTexture();
  }
  
  void attach(){
    attachedToEdge = true;
  }
  
  void detach(){
    attachedToEdge = false;
  }

  void setTopTexture() {
    placeholderTexture = topTexture;
    placeholderTextureWidth = dimensions[1];
    placeholderTextureHeight = dimensions[0];
    selectInput("Choose an image", "loadImage");
  }

  void setSideTexture() {
    placeholderTexture = sideTexture;
    placeholderTextureWidth = dimensions[1];
    placeholderTextureHeight = dimensions[2];
    selectInput("Choose an image", "loadImage");
  }

  int getLength() {
    return dimensions[0];
  }
  int getWidth() {
    return dimensions[1];
  }
  int getHeight() {
    return dimensions[2];
  }

  void setLength(int l) {
    dimensions[0] = l;
    limitDimensions();
    resizeTopTexture();
    resetBottomEdge();
  }

  void setWidth (int w) {
    dimensions[2] = w;
    limitDimensions();
    resizeTopTexture();
    resizeSideTexture();
    resetBottomEdge();
    resetTopEdge();
  }

  void setHeight (int h) {
    dimensions[3] = h;
    limitDimensions();
    resizeSideTexture();
    resetTopEdge();
  }

  void draw() {
    //the matrix will be transformed so that the middle of the spot where the cube meets the edge is 0, 0 and rotated properly
    //used in other methods so the block is drawn the same way every time
    pushStyle();
    fill(255);
    noStroke();
    rect(-dimensions[1]/2, -dimensions[2], dimensions[1], dimensions[0] + dimensions[2]);

    topTexture.draw(-dimensions[1]/2, -dimensions[2]);

    sideTexture.draw(-dimensions[1]/2, dimensions[0] - dimensions[2]);

    strokeCap(SQUARE);

    stroke(0);
    dashedLine (-dimensions[1]/2, dimensions[0] - dimensions[2], dimensions[1]/2, dimensions[0] - dimensions[2], mountain);

    cutStyle();
    line (-dimensions[1]/2, -dimensions[2], -dimensions[1]/2, dimensions[0]);
    line (dimensions[1]/2, -dimensions[2], dimensions[1]/2, dimensions[0]);
    bottom.draw();
    top.draw();

    popStyle();
  }



  void drawOutOfPlace() {
    //draw the block not attached to a wall
    pushMatrix();
    pushStyle();
    translate (x, y);


    draw();

    noStroke();
    //put a red tint over the block. Currently only effects the parent block and not children. Something to fix later**
    fill (255, 0, 0, 128);
    rect(-dimensions[1]/2, -dimensions[2], dimensions[1], dimensions[0] + dimensions[2]);
    popStyle();
    popMatrix();
  }

  void drawOnEdge() {
    //when this method is called the matrix is already transformed to the corner of the edge and is rotated properly
    pushMatrix();

    translate (position, 0);
    draw();

    popMatrix();
  }

  void drawOnEdge(PGraphics pdf) {
    //When this method is called the matrix is already transformed to the corner of the edge and is rotated properly
    //Only the properly placed blocks are output to the pdf

    pdf.pushMatrix();

    pdf.translate (position, 0);

    top.startX = -dimensions[1]/2;
    top.startY = -dimensions[2];
    top.eLength = dimensions[1];
    top.eAngle = 0;
    bottom.startX = -dimensions[1]/2;
    bottom.startY = dimensions[0];
    bottom.eLength = dimensions[1];
    bottom.eAngle = 0;

    pdf.pushStyle();
    pdf.fill(255);
    pdf.noStroke();
    pdf.rect(-dimensions[1]/2, -dimensions[2], dimensions[1], dimensions[0] + dimensions[2]);

    topTexture.draw(-dimensions[1]/2, -dimensions[2], pdf);
    sideTexture.draw(-dimensions[1]/2, dimensions[0] - dimensions[2], pdf);

    pdf.strokeCap(SQUARE);

    pdf.stroke(0);
    dashedLine (-dimensions[1]/2, dimensions[0] - dimensions[2], dimensions[1]/2, dimensions[0] - dimensions[2], mountain, pdf);


    bottom.draw(pdf);
    top.draw(pdf);

    cutStyle(pdf);
    pdf.line (-dimensions[1]/2, -dimensions[2], -dimensions[1]/2, dimensions[0]);
    pdf.line (dimensions[1]/2, -dimensions[2], dimensions[1]/2, dimensions[0]);

    pdf.popStyle();

    pdf.popMatrix();
  }
}

class DrawBlock implements Consumer<Block> {//**testing a new feature
  public DrawBlock(){
  }
  void accept(Block myBlock) {
    myBlock.drawOutOfPlace();
  }
}
