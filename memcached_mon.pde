
import net.spy.memcached.MemcachedClient;
import net.spy.memcached.AddrUtil;
import net.spy.util.RingBuffer;

// Globals
int g_winW             = 820;   // Window Width
int g_winH             = 500;   // Window Height

int gBoxX = 10;
int gBoxY = 90;
int gBoxW = 800;
int gBoxH = 400;

color bgcolor = color(0xbb, 0xbb, 0xbb);

Graph graph = new Graph(gBoxX, gBoxY, gBoxW, gBoxH);
Stat getCmds = new Stat("cmd_get", 0, 255, 0, new RingBuffer(128));
Stat setCmds = new Stat("cmd_set", 255, 0, 0, new RingBuffer(128));

Stat stats[] = {
  getCmds, setCmds};

PFont  g_font;

double x = 0;

Random rand = new Random();
MemcachedClient client = null;

void setup()
{
  try {
    client = new MemcachedClient(AddrUtil.getAddresses("127.0.0.1:11211"));
  } 
  catch(Exception e) {
    throw new RuntimeException(e);
  }
  size(g_winW, g_winH, P2D);
  smooth();
  background(bgcolor);

  g_font = loadFont("ArialMT-20.vlw");
  textFont(g_font, 20);

  // This draws the graph key info
  strokeWeight(2);

  // Visual indicators of stat nums.
  stroke(0, 255, 0);     
  line(20, 425, 35, 425);
  stroke(255, 0, 0);     
  line(20, 455, 35, 455);

  processStats(false);
  showStatNums();

  frameRate(12);
}

void draw()
{
  processStats();
  graph.setScale(stats);
  graph.drawBox();

  strokeWeight(1.5);
  graph.drawLine(getCmds);
  graph.drawLine(setCmds);
}

void showStatNums() {
  noSmooth();
  strokeWeight(1);
  rectMode(CORNER);
  noStroke();
  fill(bgcolor);
  rect(40, 410, 800, 70);
  fill(0);
  text("gets " + getCmds.prev + " +" + getCmds.prevDelta, 40, 430);
  text("sets " + setCmds.prev + " +" + getCmds.prevDelta, 40, 460);
  smooth();
}

void processStats(boolean add) {
  try {
    Map s = client.getStats().values().iterator().next();
    for(int i = 0; i < stats.length; i++) {
      stats[i].add(s);
    }
  }
  catch(Exception e) {
    e.printStackTrace();
  }
  showStatNums();
}

void processStats() {
  processStats(true);
}

class Stat {
  int r, g, b;
  // float min = 0, max = 0;
  int prev = Integer.MIN_VALUE, prevDelta = 0;
  String name;
  RingBuffer data;

  public Stat(String n, int rColor, int gColor, int bColor, RingBuffer d) {
    name = n;
    r = rColor;
    g = gColor;
    b = bColor;
    data = d;
  }

  public void add(Map stats) {
    int v = Integer.parseInt((String)stats.get(name));
    if (!(data.size() == 0 && prev == Integer.MIN_VALUE)) {
      prevDelta = v - prev;
      data.add(v - prev);
    }
    prevDelta = v - prev;
    prev = v;
  }
}

// This class takes the data and helps graph it
class Graph
{
  float m_gWidth, m_gHeight;
  float m_gLeft, m_gBottom, m_gRight, m_gTop;
  float graphMultY;
  float min, max;

  Graph(float x, float y, float w, float h)
  {
    m_gWidth     = w;
    m_gHeight    = h;
    m_gLeft      = x;
    m_gBottom    = g_winH - y;
    m_gRight     = x + w;
    m_gTop       = g_winH - y - h;
    graphMultY = 1;
  }

  void drawBox()
  {
    stroke(0);
    strokeWeight(2);
    fill(255, 255, 255);
    rectMode(CORNERS);
    rect(m_gLeft, m_gBottom, m_gRight, m_gTop);
  }

  void setScale(Stat stats[]) {
    min = 0;
    max = 1000000;

    float denom = log10(max) - log10(min);
    graphMultY = m_gHeight/denom;
    /*
    System.out.println("denom = " + denom + ", min=" + min + ", max=" + max
     + " multipier = " + graphMultY);
     */
  }

  void drawLine(Stat s)
  {

    if (s.data.size() < 2 ) {
      return;
    }

    stroke(s.r, s.g, s.b);

    float graphMultX = m_gWidth/s.data.size();

    int i = 0;
    Iterator it = s.data.iterator();
    int prev = (Integer)it.next();
    for(int l = (Integer)it.next(); it.hasNext(); l = (Integer)it.next()) {
      /*
      float x0 = i*graphMultX+m_gLeft;
       float y0 = m_gBottom-((prev-s.min)*graphMultY);
       float x1 = (i+1)*graphMultX+m_gLeft;
       float y1 = m_gBottom-((l-s.min)*graphMultY);
       */

      float x0 = i*graphMultX+m_gLeft;
      float y0 = m_gBottom-((log10(prev)-log10(min))*graphMultY);
      float x1 = (i+1)*graphMultX+m_gLeft;
      float y1 = m_gBottom-((log10(l)-log10(min))*graphMultY);
      line(x0, y0, x1, y1);
      i++;
      prev = l;
    }
  }
}

float log10 (float x) {
  if (x == 0) {
    return 0;
  }
  float rv = (log(x) / log(10));
  return rv;
}

