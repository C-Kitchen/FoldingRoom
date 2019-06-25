class EdgeDistance {
  /*
  This is used to store an edge and your relation to it
   The initial check of an edge involves some trig, so that initial check is stored
   Child edges are compared easily since you can use basic arithmatic to know your relation to them based on the parent edge
   */
  Edge edge;
  int distance, position;
  public EdgeDistance(Edge edgei, int distancei, int positioni) {
    edge = edgei;
    distance = distancei;
    position = positioni;
  }
}

class Edge {
  int startX, startY, eLength; //These keep track of the points. If you're traveling from start to end, the inside is on the right
  float eAngle;
  //for now I'm focusing only on rooms with four walls at right angles, but the code is fairly general
  LinkedList<Block> cubes; //the list of cubes attached to this edge. Since the top and bottom of cubes are edges, some recursion is necessary
  Block temp; //this stores the selectedBlock if this edge is the best one

  public Edge (int x1, int y1, int eLengthi, float eAnglei) {
    startX = x1;
    startY = y1;
    eLength = eLengthi;
    eAngle = eAnglei;
    cubes = new LinkedList<Block>();
  }

  private Edge (int x1, int y1, int eLengthi, float eAnglei, LinkedList<Block> cubesi) {
    startX = x1;
    startY = y1;
    eLength = eLengthi;
    eAngle = eAnglei;
    cubes = cubesi;
  }

  EdgeDistance startGetBest(int checkX, int checkY, Block c) {
    int x = checkX - startX;
    int y = checkY - startY;
    float cosAngle = cos(-eAngle);
    float sinAngle = sin(-eAngle);
    int v = (int) (x * cosAngle - y * sinAngle);

    if (v < 0 || v > eLength) {
      return null;
    }
    return getBest(v, (int) (x * sinAngle + y * cosAngle), c);
  }

  EdgeDistance getBest(int position, int distance, Block c) {
    //this returns an edge and distance so that children of the initial 4 edges can be compared
    ListIterator i = cubes.listIterator();
    Block current;

    //min and max keep track of where the block can be without colliding with blocks on the same edge
    int minPosition = c.getWidth()/2;
    int maxPosition = eLength - c.getWidth()/2;
    while (i.hasNext()) {
      current = (Block) i.next();

      if (current.position - current.getWidth()/2 > position) {
        maxPosition = current.position - current.getWidth()/2 - c.getWidth()/2;
        break;
      } else if (current.position + current.getWidth()/2 > position) {
        EdgeDistance t = (current.top).getBest(position - current.position + current.getWidth()/2, distance + current.getHeight(), c);
        EdgeDistance b = (current.bottom).getBest(position - current.position + current.getWidth()/2, distance - current.getLength(), c);
        if (t == null) {
          return b;
        } else if (b == null) {
          return t;
        } else {
          return t.distance > b.distance ? b : t;
        }
      }
      minPosition = current.position + current.getWidth()/2 + c.getWidth()/2;
    }
    if (distance < c.getLength() && distance > -c.getHeight() && (minPosition <= maxPosition)) {
      //if the point being checked (the mouse cursor) is within where the block would be if it were placed on the edge and there is a big enough gap along the edge for the block, then this is an allowable edge (need to return distance to compare to edges from other starting walls)
      return new EdgeDistance(this, distance, max(min(position, maxPosition), minPosition));
    } else {
      //if this edge isn't allowable
      return null;
    }
  }

  Edge clone() {
    LinkedList<Block> cubesClone = new LinkedList<Block>();
    ListIterator i = cubes.listIterator();
    while (i.hasNext()) {
      cubesClone.add(((Block) i.next()).clone());
    }
    return new Edge(startX, startY, eLength, eAngle, cubesClone);
  }

  void addBlock (Block c) {
    //adds block to the list in order of increasing position
    if (cubes.size() == 0 || (cubes.peekLast()).position < c.position) {
      //flag1 = true;
      cubes.add(c);
    } else {
      ListIterator i = cubes.listIterator();

      Block tempC;
      while (i.hasNext()) {
        tempC = (Block) i.next();
        if (tempC.position > c.position) {
          i.previous();
          i.add(c);
          break;
        }
      }
    }
  }

  Block startFindBlock (int checkX, int checkY) {
    int x = checkX - startX; //adjust the point to the edge
    int y = checkY - startY;
    float cosAngle = cos(-eAngle);
    float sinAngle = sin(-eAngle);
    int projectionOntoEdge = (int) (x * cosAngle - y * sinAngle); //find the projection onto the edge
    if (projectionOntoEdge < 0 || projectionOntoEdge > eLength) {
      //the projection lies outside the limits of the edge
      return null;
    }
    //check the blocks on this edge to see if any are under the point being checked
    return findBlock(projectionOntoEdge, (int) (x * sinAngle + y * cosAngle));
  }

  Block findBlock (int position, int distance) {
    //after the position (the projection onto this edge) and the distance have been found, recursively check the child blocks for the lowest tier edge that the point being checked (mouse position) is within
    ListIterator i = cubes.listIterator();
    Block current, tempC;

    current = null;
    while (i.hasNext()) {
      tempC = (Block) i.next();
      if (position < tempC.position - tempC.getWidth()/2) {
        return null;
      } else if (position <= tempC.position + tempC.getWidth()/2) {
        if (distance >= -tempC.getHeight() && distance <= tempC.getLength()) {
          current = tempC;
        }
        Block cTop = (tempC.top).findBlock(position - tempC.position + tempC.getWidth()/2, distance + tempC.getHeight());
        if (cTop != null) {
          current = cTop;
        } else {
          Block cBottom = (tempC.bottom).findBlock(position - tempC.position + tempC.getWidth()/2, distance - tempC.getLength());
          if (cBottom != null) {
            current = cBottom;
          }
        }
        if (current == tempC) {
          i.remove();
        }
        break;
      }
    }
    return current;
  }

  void draw() {
    pushMatrix();
    pushStyle();

    stroke (0);

    translate (startX, startY);
    rotate(eAngle);

    dashedLine (0, 0, eLength, 0, valley);
    popStyle();

    ListIterator i = cubes.listIterator(0);
    while (i.hasNext()) {

      ((Block) i.next()).drawOnEdge();
    }
    if (temp != null) {
      temp.drawOnEdge();
    }
    temp = null;
    popMatrix();
  }

  void draw(PGraphics pdf) {
    pdf.pushMatrix();
    pdf.pushStyle();

    pdf.stroke (0);

    pdf.translate (startX, startY);
    pdf.rotate(eAngle);

    dashedLine (0, 0, eLength, 0, valley, pdf);
    pdf.popStyle();


    ListIterator i = cubes.listIterator(0);
    while (i.hasNext()) {

      ((Block) i.next()).drawOnEdge(pdf);
    }
    pdf.popMatrix();
  }
}
