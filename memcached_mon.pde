
import net.spy.memcached.MemcachedClient;
import net.spy.memcached.AddrUtil;
import net.spy.util.RingBuffer;

// Globals
int g_winW             = 820;   // Window Width
int g_winH             = 0;   // Window Height

int gBoxX = 10;
int gBoxY = 10;
int gBoxW = 800;
int gBoxH = 400;

color bgcolor = color(0xbb, 0xbb, 0xbb);

Graph graph;

Stat stats[] = {
  new Stat("gets", "cmd_get", 0, 255, 0, new RingBuffer(128)),
  new Stat("sets", "cmd_set", 255, 0, 0, new RingBuffer(128))
};

PFont  g_font;

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

  g_winH = gBoxH + 10 + (stats.length * 30);
  System.out.println("height is " + g_winH);

  size(g_winW, g_winH, P2D);
  graph = new Graph(gBoxX, gBoxY, gBoxW, gBoxH);
  smooth();
  background(bgcolor);

  g_font = loadFont("ArialMT-20.vlw");
  textFont(g_font, 20);

  // This draws the graph key info
  strokeWeight(2);

  // Visual indicators of stat nums.
  int strokeY = g_winH + 15 - (30 * stats.length);
  for(int i = 0; i < stats.length; i++) {
      stroke(stats[i].r, stats[i].g, stats[i].b);
      line(20, strokeY, 35, strokeY);
      strokeY += 30;
  }

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
  for (int i = 0; i < stats.length; i++) {
    graph.drawLine(stats[i]);
  }
}

void showStatNums() {
  noSmooth();
  strokeWeight(1);
  rectMode(CORNER);
  noStroke();
  fill(bgcolor);
  int labelTop = g_winH - (stats.length * 30);
  rect(40, labelTop, 800, 20 + (stats.length * 30));
  fill(0);

  int textY = labelTop + 20;
  for(int i = 0; i < stats.length; i++) {
    text(stats[i].name + " " + stats[i].prev
      + " +" + stats[i].prevDelta, 40, textY);
    textY += 30;
  }
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
  // double min = 0, max = 0;
  long prev = Integer.MIN_VALUE, prevDelta = 0;
  String name, stat;
  RingBuffer data;

  public Stat(String n, String st, int rColor, int gColor, int bColor,
    RingBuffer d) {
    name = n;
    stat = st;
    r = rColor;
    g = gColor;
    b = bColor;
    data = d;
  }

  public void add(Map stats) {
    long v = Long.parseLong((String)stats.get(stat));
    if (!(data.size() == 0 && prev == Long.MIN_VALUE)) {
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
  double graphMultY;
  double min, max;

  Graph(float x, float y, float w, float h)
  {
    m_gWidth     = w;
    m_gHeight    = h;
    m_gLeft      = x;
    m_gBottom    = h + y;
    m_gRight     = x + w;
    m_gTop       = y;

    graphMultY = 1;
  }

  void drawBox()
  {
    stroke(0);
    strokeWeight(2);
    fill(255, 255, 255);
    rectMode(CORNER);
    rect(m_gLeft, m_gTop, m_gWidth, m_gHeight);
  }

  void setScale(Stat stats[]) {
    min = 0;
    max = 1000000;

    double denom = log10(max) - log10(min);
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

    double graphMultX = m_gWidth/s.data.size();

    int i = 0;
    Iterator it = s.data.iterator();
    long prev = (Long)it.next();
    for(long l = (Long)it.next(); it.hasNext(); l = (Long)it.next()) {
      float x0 = (float)(i*graphMultX+m_gLeft);
      float y0 = constrain((float)(m_gBottom-((log10(prev)-log10(min))*graphMultY)),
                           m_gTop, m_gBottom+1);
      float x1 = (float)((i+1)*graphMultX+m_gLeft);
      float y1 = constrain((float)(m_gBottom-((log10(l)-log10(min))*graphMultY)),
                           m_gTop, m_gBottom+1);

      line(x0, y0, x1, y1);
      i++;
      prev = l;
    }
  }
}

double log10 (double x) {
  if (x == 0) {
    return 0;
  }
  double rv = (Math.log(x) / Math.log(10));
  return rv;
}

