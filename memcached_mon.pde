
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

int baseTextSize = 16;

static final int FRAME_RATE = 12;

color bgcolor = color(0xbb, 0xbb, 0xbb);

Graph graph;

Stat stats[] = {
  new DeltaStat("gets", "cmd_get", 0, 255, 0),
  new DeltaStat("sets", "cmd_set", 255, 0, 0),
  // new AbsStat("items", "total_items", 0, 0, 255),
};

PFont  g_font;

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
  textSize(baseTextSize);

  // Visual indicators of stat nums.
  int strokeY = g_winH + 15 - (30 * stats.length);
  for(int i = 0; i < stats.length; i++) {
      stroke(stats[i].r, stats[i].g, stats[i].b);
      line(20, strokeY, 35, strokeY);
      strokeY += 30;
  }

  processStats(false);
  showStatNums();

  frameRate(FRAME_RATE);
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
  textSize(baseTextSize);
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
    text(stats[i].getLabel(), 40, textY);
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

abstract class Stat {
  int r, g, b;
  long max, min;
  long prev = 0;
  String name, stat;
  RingBuffer data = new RingBuffer(128);

  public Stat(String n, String st, int rColor, int gColor, int bColor) {
    name = n;
    stat = st;
    r = rColor;
    g = gColor;
    b = bColor;
    max = 0;
    min = 0;
  }

  public abstract void add(Map stats);

  public void computeLimits() {
    max = min = 0;
    for(Iterator it = data.iterator(); it.hasNext(); ) {
      Long v = (Long)it.next();
      max = Math.max(v, max);
      min = Math.min(v, min);
    }
  }

  public String getLabel() {
    return name + " " + prev;
  }
}

class DeltaStat extends Stat {

  long prevDelta = 0;
  boolean added = false;

  public DeltaStat(String n, String st, int rColor, int gColor, int bColor) {
    super(n, st, rColor, gColor, bColor);
  }

  public void add(Map stats) {
    long v = Long.parseLong((String)stats.get(stat)) * FRAME_RATE;
    if (!(data.size() == 0 && !added)) {
      prevDelta = v - prev;
      data.add(v - prev);
    }
    added = true;
    prevDelta = v - prev;
    prev = v;
    computeLimits();
  }

  public String getLabel() {
    return super.getLabel() + " +" + prevDelta;
  }
}

class AbsStat extends Stat {

  public AbsStat(String n, String st, int rColor, int gColor, int bColor) {
    super(n, st, rColor, gColor, bColor);
  }

  public void add(Map stats) {
    long v = Long.parseLong((String)stats.get(stat));
    if (!(data.size() == 0 && prev == Long.MIN_VALUE)) {
      data.add(v);
    }
    prev = v;
    computeLimits();
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
    stroke(#555555);
    strokeWeight(2);
    fill(#222222);
    rectMode(CORNER);
    rect(m_gLeft, m_gTop, m_gWidth, m_gHeight);
    fill(#cccccc);
    textSize(11);
    strokeWeight(1);
    for (long i = 1; i < max; i *= 10) {
      float y = translateY(i);
      line(m_gLeft, y, m_gRight, y);
      text(label(i), m_gRight - 30, y - 2);
    }
  }

  String label(long v) {
    String label[] = {"", "K", "M", "G", "T"};
    int om = 0;
    long outv = v;
    while (outv >= 1000) {
      outv /= 1000;
      om++;
    }
    return outv + label[om];
  }

  void setScale(Stat stats[]) {
    min = Long.MAX_VALUE;
    max = Long.MIN_VALUE;

    for(int i = 0; i < stats.length; i++) {
      min = Math.max(0, Math.min(stats[i].min, min));
      max = Math.max(stats[i].max, max);
    }

    if (min == Long.MAX_VALUE) {
      return;
    }

    max = Math.max(10, pow(10, ceil((float)log10(max))));

    double denom = log10(max) - log10(min);
    graphMultY = m_gHeight/denom;
//    System.out.println("denom = " + denom + ", min=" + min + ", max=" + max
//     + " multipier = " + graphMultY);
  }

  void drawLine(Stat s)
  {

    if (s.data.size() < 2 || min == Long.MAX_VALUE ) {
      return;
    }

    stroke(s.r, s.g, s.b);

    double graphMultX = m_gWidth/s.data.size();

    int i = 0;
    Iterator it = s.data.iterator();
    long prev = (Long)it.next();
    for(long l = (Long)it.next(); it.hasNext(); l = (Long)it.next()) {
      float x0 = (float)(i*graphMultX+m_gLeft);
      float y0 = translateY(prev);
      float x1 = (float)((i+1)*graphMultX+m_gLeft);
      float y1 = translateY(l);

      line(x0, y0, x1, y1);
      i++;
      prev = l;
    }
  }

  float translateY(long input) {
    return constrain((float)(m_gBottom-((log10(input)-log10(min))*graphMultY)),
                           m_gTop, m_gBottom+1);
  }
}

double log10 (double x) {
  if (x == 0) {
    return 0;
  }
  double rv = (Math.log(x) / Math.log(10));
  return rv;
}

