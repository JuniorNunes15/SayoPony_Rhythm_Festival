class ChartEntry {
  float time;
  int lane;
  float endTime; // -1 if not hold
  boolean isHold;

  ChartEntry(float t, int l) {
    time = t; lane = l; endTime = -1; isHold = false;
  }
  ChartEntry(float t, int l, float e) {
    time = t; lane = l; endTime = e; isHold = true;
  }
}

class Chart {
  ArrayList<ChartEntry> entries;

  Chart() {
    entries = new ArrayList<ChartEntry>();
  }

  void add(float t, int lane) {
    entries.add(new ChartEntry(t, lane));
    entries.sort((a,b) -> Float.compare(a.time, b.time));
  }

  void addHold(float t, int lane, float endT) {
    entries.add(new ChartEntry(t, lane, endT));
    entries.sort((a,b) -> Float.compare(a.time, b.time));
  }

  void clear() {
    entries.clear();
  }

  void load(String path) {
    entries.clear();
    try {
      String[] lines = loadStrings(path);
      if (lines == null) return;
      for (String l : lines) {
        l = trim(l);
        if (l.length() == 0) continue;
        // format: time,lane[,endTime]
        String[] p = splitTokens(l, ",");
        if (p.length >= 2) {
          float t = float(p[0]);
          int lane = int(p[1]);
          if (p.length == 3) {
            float e = float(p[2]);
            addHold(t, lane, e);
          } else {
            add(t, lane);
          }
        }
      }
      println("Chart carregado: " + path + " entradas: " + entries.size());
    } catch (Exception e) {
      println("Nenhum chart encontrado em " + path + " (arquivo pode não existir).");
    }
  }

  void save(String path) {
    ArrayList<String> out = new ArrayList<String>();
    for (ChartEntry ce : entries) {
      if (ce.isHold) out.add(ce.time + "," + ce.lane + "," + ce.endTime);
      else out.add(ce.time + "," + ce.lane);
    }
    String[] outA = new String[out.size()];
    for (int i = 0; i < out.size(); i++) outA[i] = out.get(i);
    saveStrings(path, outA);
    println("Chart salvo -> " + path);
  }
}
