// Small PDF text and picture extractor for WPS Writer / Word style PDFs (no object streams).
// Used to read the Nigerian curriculum lesson notes without paying for page images.
// Compile and run from PowerShell:  powershell -ExecutionPolicy Bypass -File tools\pdf_extract\extract.ps1 -Pdf x.pdf -Out outdir
// Output: <Out>\text.txt (one block per page, pictures marked [IMG ...]) and <Out>\img\*.jpg|png (watermark skipped).
// C# 5 syntax only (Add-Type in Windows PowerShell 5.1).
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

public class PObj { public int Id; public string Dict; public byte[] Raw; public bool HasStream; }
public class FontInfo {
  public bool TwoByte; public bool Mono; public string Name = "";
  public Dictionary<int, string> Map = new Dictionary<int, string>();
  public Dictionary<int, double> W = new Dictionary<int, double>();
  public double DW = 1000;
}
public class TItem { public double X, Y, Fs, W; public string T; public bool Mono; }
public class IItem { public double X, Y, W, H; public int ObjId; }

public static class PdfX {
  static Encoding L1 = Encoding.GetEncoding(28591);
  static Dictionary<int, PObj> objs;
  static Dictionary<int, FontInfo> fontCache = new Dictionary<int, FontInfo>();

  static string S(byte[] b) { return L1.GetString(b); }

  static byte[] Inflate(byte[] d) {
    try {
      using (MemoryStream ms = new MemoryStream(d, 2, d.Length - 2))
      using (DeflateStream ds = new DeflateStream(ms, CompressionMode.Decompress))
      using (MemoryStream o = new MemoryStream()) { ds.CopyTo(o); return o.ToArray(); }
    } catch (Exception) { return new byte[0]; }
  }

  public static void Load(byte[] b) {
    string s = S(b);
    objs = new Dictionary<int, PObj>();
    Regex rx = new Regex(@"(?:^|[\r\n])(\d+)\s+(\d+)\s+obj\b");
    int pos = 0;
    while (true) {
      Match m = rx.Match(s, pos);
      if (!m.Success) break;
      int id = int.Parse(m.Groups[1].Value);
      int start = m.Index + m.Length;
      int endobj = s.IndexOf("endobj", start, StringComparison.Ordinal);
      int stIdx = s.IndexOf("stream", start, StringComparison.Ordinal);
      PObj o = new PObj(); o.Id = id;
      if (stIdx >= 0 && (endobj < 0 || stIdx < endobj) && !s.Substring(Math.Max(start, stIdx - 3), 3).Equals("end")) {
        o.Dict = s.Substring(start, stIdx - start);
        int ds = stIdx + 6;
        if (ds < s.Length && s[ds] == '\r') ds++;
        if (ds < s.Length && s[ds] == '\n') ds++;
        int len = -1;
        Match lm = Regex.Match(o.Dict, @"/Length\s+(\d+)(?!\s+\d+\s+R)");
        if (lm.Success) len = int.Parse(lm.Groups[1].Value);
        int de;
        if (len >= 0 && ds + len <= s.Length && s.IndexOf("endstream", ds + len, Math.Min(20, s.Length - ds - len) , StringComparison.Ordinal) >= 0) de = ds + len;
        else { de = s.IndexOf("endstream", ds, StringComparison.Ordinal); if (de < 0) de = s.Length; while (de > ds && (s[de - 1] == '\n' || s[de - 1] == '\r')) de--; }
        byte[] raw = new byte[de - ds]; Array.Copy(b, ds, raw, 0, raw.Length);
        o.Raw = raw; o.HasStream = true;
        pos = de;
        int ee = s.IndexOf("endobj", de, StringComparison.Ordinal); if (ee >= 0) pos = ee;
      } else {
        o.Dict = endobj >= 0 ? s.Substring(start, endobj - start) : s.Substring(start);
        pos = endobj >= 0 ? endobj : s.Length;
      }
      objs[id] = o;
      if (pos >= s.Length) break;
    }
  }

  static byte[] Decoded(PObj o) {
    if (o == null || !o.HasStream) return new byte[0];
    if (o.Dict.Contains("FlateDecode") && !o.Dict.Contains("DCTDecode")) return Inflate(o.Raw);
    return o.Raw;
  }

  static string MatchDict(string s, int idx) {
    int depth = 0; int i = idx;
    while (i < s.Length - 1) {
      if (s[i] == '<' && s[i + 1] == '<') { depth++; i += 2; continue; }
      if (s[i] == '>' && s[i + 1] == '>') { depth--; i += 2; if (depth == 0) return s.Substring(idx, i - idx); continue; }
      i++;
    }
    return s.Substring(idx);
  }

  // value of /Key as a dictionary text (inline << >> or the dict of the referenced object)
  static string GetDict(string d, string key) {
    Match m = Regex.Match(d, "/" + key + @"(?![A-Za-z0-9])\s*");
    if (!m.Success) return null;
    int p = m.Index + m.Length;
    if (p + 1 < d.Length && d[p] == '<' && d[p + 1] == '<') return MatchDict(d, p);
    Match r = Regex.Match(d.Substring(p), @"^(\d+)\s+(\d+)\s+R");
    if (r.Success) { PObj o; if (objs.TryGetValue(int.Parse(r.Groups[1].Value), out o)) return o.Dict; }
    return null;
  }
  static string GetRaw(string d, string key) {
    Match m = Regex.Match(d, "/" + key + @"(?![A-Za-z0-9])\s*");
    if (!m.Success) return null;
    int p = m.Index + m.Length;
    Match r = Regex.Match(d.Substring(p, Math.Min(40, d.Length - p)), @"^(\d+)\s+(\d+)\s+R");
    if (r.Success) { PObj o; if (objs.TryGetValue(int.Parse(r.Groups[1].Value), out o)) { string t0 = o.Dict.Trim(); return t0.StartsWith("[") ? MatchArray(t0, 0) : t0; } }
    if (p < d.Length && d[p] == '[') { return MatchArray(d, p); }
    Match v = Regex.Match(d.Substring(p), @"^[^/>\s][^/>]*");
    return v.Success ? v.Value.Trim() : null;
  }

  static string MatchArray(string s, int idx) {
    int depth = 0;
    for (int i = idx; i < s.Length; i++) {
      if (s[i] == '[') depth++;
      else if (s[i] == ']') { depth--; if (depth == 0) return s.Substring(idx, i - idx + 1); }
    }
    return s.Substring(idx);
  }

  static List<int> Pages() {
    List<int> res = new List<int>();
    int root = -1;
    foreach (PObj o in objs.Values) if (Regex.IsMatch(o.Dict, @"/Type\s*/Catalog")) { Match m = Regex.Match(o.Dict, @"/Pages\s+(\d+)\s+\d+\s+R"); if (m.Success) root = int.Parse(m.Groups[1].Value); }
    if (root < 0) return res;
    Walk(root, res);
    return res;
  }
  static void Walk(int id, List<int> res) {
    PObj o; if (!objs.TryGetValue(id, out o)) return;
    if (Regex.IsMatch(o.Dict, @"/Kids\s*\[")) {
      Match k = Regex.Match(o.Dict, @"/Kids\s*\[(.*?)\]", RegexOptions.Singleline);
      foreach (Match r in Regex.Matches(k.Groups[1].Value, @"(\d+)\s+\d+\s+R")) Walk(int.Parse(r.Groups[1].Value), res);
    } else res.Add(id);
  }

  static string HexToStr(string h) {
    h = Regex.Replace(h, @"\s+", "");
    if (h.Length % 2 == 1) h += "0";
    byte[] b = new byte[h.Length / 2];
    for (int i = 0; i < b.Length; i++) b[i] = Convert.ToByte(h.Substring(i * 2, 2), 16);
    if (b.Length == 1) return ((char)b[0]).ToString();
    return Norm(Encoding.BigEndianUnicode.GetString(b));
  }

  // mathematical alphanumeric letters (italic x, bold A ...) to plain ASCII so the text is portable
  static string Norm(string s) {
    bool any = false; foreach (char c in s) if (char.IsSurrogate(c)) { any = true; break; }
    if (!any) return s;
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < s.Length; i++) {
      if (char.IsHighSurrogate(s[i]) && i + 1 < s.Length && char.IsLowSurrogate(s[i + 1])) {
        int cp = char.ConvertToUtf32(s[i], s[i + 1]); i++;
        if (cp >= 0x1D400 && cp <= 0x1D6A3) { int idx = (cp - 0x1D400) % 52; sb.Append((char)(idx < 26 ? 'A' + idx : 'a' + idx - 26)); }
        else if (cp >= 0x1D7CE && cp <= 0x1D7FF) sb.Append((char)('0' + (cp - 0x1D7CE) % 10));
        else sb.Append(char.ConvertFromUtf32(cp));
      } else sb.Append(s[i]);
    }
    return sb.ToString();
  }

  static FontInfo GetFont(int id) {
    FontInfo f;
    if (fontCache.TryGetValue(id, out f)) return f;
    f = new FontInfo(); fontCache[id] = f;
    PObj o; if (!objs.TryGetValue(id, out o)) return f;
    string d = o.Dict;
    Match nm = Regex.Match(d, @"/BaseFont\s*/([^\s/\[<]+)"); if (nm.Success) f.Name = nm.Groups[1].Value;
    f.Mono = Regex.IsMatch(f.Name, "Consolas|Courier|Mono|Cascadia|LucidaConsole|Menlo", RegexOptions.IgnoreCase);
    f.TwoByte = Regex.IsMatch(d, @"/Subtype\s*/Type0");
    // ToUnicode
    Match tu = Regex.Match(d, @"/ToUnicode\s+(\d+)\s+\d+\s+R");
    if (tu.Success) {
      PObj t; if (objs.TryGetValue(int.Parse(tu.Groups[1].Value), out t)) {
        string cm = S(Decoded(t));
        Match cs = Regex.Match(cm, @"begincodespacerange\s*<([0-9A-Fa-f]+)>");
        if (cs.Success) f.TwoByte = cs.Groups[1].Value.Length >= 4;
        foreach (Match bc in Regex.Matches(cm, @"beginbfchar(.*?)endbfchar", RegexOptions.Singleline))
          foreach (Match p in Regex.Matches(bc.Groups[1].Value, @"<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>"))
            f.Map[Convert.ToInt32(p.Groups[1].Value, 16)] = HexToStr(p.Groups[2].Value);
        foreach (Match br in Regex.Matches(cm, @"beginbfrange(.*?)endbfrange", RegexOptions.Singleline))
          foreach (Match p in Regex.Matches(br.Groups[1].Value, @"<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*(?:<([0-9A-Fa-f]+)>|\[(.*?)\])", RegexOptions.Singleline)) {
            int lo = Convert.ToInt32(p.Groups[1].Value, 16), hi = Convert.ToInt32(p.Groups[2].Value, 16);
            if (p.Groups[3].Success) {
              string baseS = HexToStr(p.Groups[3].Value);
              for (int c = lo; c <= hi && c - lo < 70000; c++) {
                if (baseS.Length == 0) continue;
                char[] ch = baseS.ToCharArray(); ch[ch.Length - 1] = (char)(ch[ch.Length - 1] + (c - lo));
                f.Map[c] = new string(ch);
              }
            } else {
              int c = lo;
              foreach (Match h in Regex.Matches(p.Groups[4].Value, @"<([0-9A-Fa-f]+)>")) { f.Map[c++] = HexToStr(h.Groups[1].Value); }
            }
          }
      }
    }
    // widths
    if (f.TwoByte) {
      Match df = Regex.Match(d, @"/DescendantFonts\s*\[?\s*(\d+)\s+\d+\s+R");
      string cid = null;
      if (df.Success) { PObj c; if (objs.TryGetValue(int.Parse(df.Groups[1].Value), out c)) cid = c.Dict; }
      else { cid = d; }
      if (cid != null) {
        Match dw = Regex.Match(cid, @"/DW\s+(\d+(\.\d+)?)"); if (dw.Success) f.DW = double.Parse(dw.Groups[1].Value, CultureInfo.InvariantCulture);
        string w = GetRaw(cid, "W");
        if (w != null) ParseCidW(w, f);
      }
    } else {
      Match fc = Regex.Match(d, @"/FirstChar\s+(\d+)");
      string wd = GetRaw(d, "Widths");
      if (fc.Success && wd != null) {
        int first = int.Parse(fc.Groups[1].Value); int i = 0;
        foreach (Match n in Regex.Matches(wd, @"-?\d+(\.\d+)?")) { f.W[first + i] = double.Parse(n.Value, CultureInfo.InvariantCulture); i++; }
      }
    }
    return f;
  }
  static void ParseCidW(string w, FontInfo f) {
    // forms: c [w1 w2 ...]   or   c1 c2 w
    w = w.Trim(); if (w.StartsWith("[")) w = w.Substring(1); if (w.EndsWith("]")) w = w.Substring(0, w.Length - 1);
    int i = 0;
    Regex tok = new Regex(@"\[|\]|-?\d+(\.\d+)?");
    List<string> t = new List<string>(); foreach (Match m in tok.Matches(w)) t.Add(m.Value);
    while (i < t.Count) {
      int c1 = (int)double.Parse(t[i], CultureInfo.InvariantCulture); i++;
      if (i >= t.Count) break;
      if (t[i] == "[") {
        i++; int c = c1;
        while (i < t.Count && t[i] != "]") { f.W[c++] = double.Parse(t[i], CultureInfo.InvariantCulture); i++; }
        i++;
      } else {
        if (i + 1 >= t.Count) break;
        int c2 = (int)double.Parse(t[i], CultureInfo.InvariantCulture); double ww = double.Parse(t[i + 1], CultureInfo.InvariantCulture); i += 2;
        for (int c = c1; c <= c2 && c - c1 < 70000; c++) f.W[c] = ww;
      }
    }
  }

  // ---- matrices (row vectors, PDF style) ----
  static double[] Mul(double[] a, double[] b) {
    return new double[] { a[0] * b[0] + a[1] * b[2], a[0] * b[1] + a[1] * b[3], a[2] * b[0] + a[3] * b[2], a[2] * b[1] + a[3] * b[3], a[4] * b[0] + a[5] * b[2] + b[4], a[4] * b[1] + a[5] * b[3] + b[5] };
  }

  // ---- content stream tokenizer ----
  static List<object> Tokens(string s) {
    List<object> t = new List<object>(); int i = 0, n = s.Length;
    Stack<List<object>> st = new Stack<List<object>>(); List<object> cur = t;
    while (i < n) {
      char c = s[i];
      if (char.IsWhiteSpace(c) || c == '\0') { i++; continue; }
      if (c == '%') { while (i < n && s[i] != '\n' && s[i] != '\r') i++; continue; }
      if (c == '[') { List<object> a = new List<object>(); cur.Add(a); st.Push(cur); cur = a; i++; continue; }
      if (c == ']') { if (st.Count > 0) cur = st.Pop(); i++; continue; }
      if (c == '(') {
        int depth = 1; i++; List<byte> b = new List<byte>();
        while (i < n && depth > 0) {
          char d = s[i];
          if (d == '\\') {
            i++; if (i >= n) break; char e = s[i];
            if (e == 'n') b.Add(10); else if (e == 'r') b.Add(13); else if (e == 't') b.Add(9); else if (e == 'b') b.Add(8); else if (e == 'f') b.Add(12);
            else if (e >= '0' && e <= '7') { int v = 0, k = 0; while (k < 3 && i < n && s[i] >= '0' && s[i] <= '7') { v = v * 8 + (s[i] - '0'); i++; k++; } b.Add((byte)(v & 255)); continue; }
            else if (e == '\r') { if (i + 1 < n && s[i + 1] == '\n') i++; }
            else if (e == '\n') { }
            else b.Add((byte)e);
            i++; continue;
          }
          if (d == '(') depth++;
          if (d == ')') { depth--; if (depth == 0) { i++; break; } }
          b.Add((byte)d); i++;
        }
        cur.Add(b.ToArray()); continue;
      }
      if (c == '<' && i + 1 < n && s[i + 1] == '<') { i += 2; continue; }
      if (c == '>' && i + 1 < n && s[i + 1] == '>') { i += 2; continue; }
      if (c == '<') {
        int e = s.IndexOf('>', i); if (e < 0) break;
        string h = Regex.Replace(s.Substring(i + 1, e - i - 1), @"\s+", ""); if (h.Length % 2 == 1) h += "0";
        byte[] b = new byte[h.Length / 2]; for (int k = 0; k < b.Length; k++) b[k] = Convert.ToByte(h.Substring(k * 2, 2), 16);
        cur.Add(b); i = e + 1; continue;
      }
      if (c == '/') { int j = i + 1; while (j < n && !char.IsWhiteSpace(s[j]) && "/[]()<>%".IndexOf(s[j]) < 0) j++; cur.Add("/" + s.Substring(i + 1, j - i - 1)); i = j; continue; }
      int q = i; while (q < n && !char.IsWhiteSpace(s[q]) && "/[]()<>%".IndexOf(s[q]) < 0) q++;
      string w = s.Substring(i, q - i); i = q;
      double dv; if (double.TryParse(w, NumberStyles.Float, CultureInfo.InvariantCulture, out dv)) cur.Add(dv); else cur.Add(new StringBuilder(w));
    }
    return t;
  }

  static string Op(object o) { StringBuilder sb = o as StringBuilder; return sb == null ? null : sb.ToString(); }
  static double Num(object o) { return o is double ? (double)o : 0; }

  public class PageResult { public List<TItem> Text = new List<TItem>(); public List<IItem> Imgs = new List<IItem>(); }

  static PageResult ReadPage(int pageId) {
    PageResult pr = new PageResult();
    PObj po = objs[pageId];
    string d = po.Dict;
    // resources (may be inherited: look up parents roughly by scanning /Parent chain)
    string res = GetDict(d, "Resources");
    string cur = d; int guard = 0;
    while (res == null && guard < 6) {
      Match pm = Regex.Match(cur, @"/Parent\s+(\d+)\s+\d+\s+R"); if (!pm.Success) break;
      PObj p; if (!objs.TryGetValue(int.Parse(pm.Groups[1].Value), out p)) break;
      cur = p.Dict; res = GetDict(cur, "Resources"); guard++;
    }
    Dictionary<string, int> fonts = new Dictionary<string, int>(); Dictionary<string, int> xo = new Dictionary<string, int>();
    if (res != null) {
      string fd = GetDict(res, "Font"); if (fd != null) foreach (Match m in Regex.Matches(fd, @"/([^\s/\[<]+)\s+(\d+)\s+\d+\s+R")) fonts[m.Groups[1].Value] = int.Parse(m.Groups[2].Value);
      string xd = GetDict(res, "XObject"); if (xd != null) foreach (Match m in Regex.Matches(xd, @"/([^\s/\[<]+)\s+(\d+)\s+\d+\s+R")) xo[m.Groups[1].Value] = int.Parse(m.Groups[2].Value);
    }
    // contents
    StringBuilder content = new StringBuilder();
    Match cm = Regex.Match(d, @"/Contents\s*(\[(.*?)\]|(\d+)\s+\d+\s+R)", RegexOptions.Singleline);
    if (cm.Success) {
      string refs = cm.Groups[2].Success ? cm.Groups[2].Value : (cm.Groups[3].Value + " 0 R");
      foreach (Match r in Regex.Matches(refs, @"(\d+)\s+\d+\s+R")) { PObj c; if (objs.TryGetValue(int.Parse(r.Groups[1].Value), out c)) { content.Append(S(Decoded(c))); content.Append('\n'); } }
    }
    List<object> tk = Tokens(content.ToString());
    double[] ctm = new double[] { 1, 0, 0, 1, 0, 0 }; Stack<double[]> gs = new Stack<double[]>();
    double[] tm = new double[] { 1, 0, 0, 1, 0, 0 }, tlm = new double[] { 1, 0, 0, 1, 0, 0 };
    double fs = 10, tc = 0, tw = 0, th = 1, tl = 0, rise = 0; FontInfo font = new FontInfo();
    List<object> args = new List<object>();
    foreach (object o in tk) {
      string op = Op(o);
      if (op == null) { args.Add(o); if (args.Count > 40) args.RemoveAt(0); continue; }
      switch (op) {
        case "q": gs.Push((double[])ctm.Clone()); break;
        case "Q": if (gs.Count > 0) ctm = gs.Pop(); break;
        case "cm": if (args.Count >= 6) { int a0 = args.Count - 6; ctm = Mul(new double[] { Num(args[a0]), Num(args[a0 + 1]), Num(args[a0 + 2]), Num(args[a0 + 3]), Num(args[a0 + 4]), Num(args[a0 + 5]) }, ctm); } break;
        case "BT": tm = new double[] { 1, 0, 0, 1, 0, 0 }; tlm = (double[])tm.Clone(); break;
        case "Tf": if (args.Count >= 2) { string fn = args[args.Count - 2] as string; if (fn != null) { fn = fn.TrimStart('/'); int fid; if (fonts.TryGetValue(fn, out fid)) font = GetFont(fid); else font = new FontInfo(); } fs = Num(args[args.Count - 1]); } break;
        case "Tc": if (args.Count >= 1) tc = Num(args[args.Count - 1]); break;
        case "Tw": if (args.Count >= 1) tw = Num(args[args.Count - 1]); break;
        case "Tz": if (args.Count >= 1) th = Num(args[args.Count - 1]) / 100.0; break;
        case "TL": if (args.Count >= 1) tl = Num(args[args.Count - 1]); break;
        case "Ts": if (args.Count >= 1) rise = Num(args[args.Count - 1]); break;
        case "Tm": if (args.Count >= 6) { int a0 = args.Count - 6; tm = new double[] { Num(args[a0]), Num(args[a0 + 1]), Num(args[a0 + 2]), Num(args[a0 + 3]), Num(args[a0 + 4]), Num(args[a0 + 5]) }; tlm = (double[])tm.Clone(); } break;
        case "Td": if (args.Count >= 2) { tlm = Mul(new double[] { 1, 0, 0, 1, Num(args[args.Count - 2]), Num(args[args.Count - 1]) }, tlm); tm = (double[])tlm.Clone(); } break;
        case "TD": if (args.Count >= 2) { tl = -Num(args[args.Count - 1]); tlm = Mul(new double[] { 1, 0, 0, 1, Num(args[args.Count - 2]), Num(args[args.Count - 1]) }, tlm); tm = (double[])tlm.Clone(); } break;
        case "T*": tlm = Mul(new double[] { 1, 0, 0, 1, 0, -tl }, tlm); tm = (double[])tlm.Clone(); break;
        case "Tj": case "'": case "\"":
          if (op != "Tj") { tlm = Mul(new double[] { 1, 0, 0, 1, 0, -tl }, tlm); tm = (double[])tlm.Clone(); }
          if (args.Count >= 1 && args[args.Count - 1] is byte[]) Show(new List<object> { args[args.Count - 1] }, font, fs, tc, tw, th, rise, ref tm, ctm, pr);
          break;
        case "TJ":
          if (args.Count >= 1 && args[args.Count - 1] is List<object>) Show((List<object>)args[args.Count - 1], font, fs, tc, tw, th, rise, ref tm, ctm, pr);
          break;
        case "Do":
          if (args.Count >= 1) {
            string xn = args[args.Count - 1] as string; int xid;
            if (xn != null && xo.TryGetValue(xn.TrimStart('/'), out xid)) {
              PObj xobj; if (objs.TryGetValue(xid, out xobj) && Regex.IsMatch(xobj.Dict, @"/Subtype\s*/Image")) {
                IItem ii = new IItem(); ii.ObjId = xid; ii.X = ctm[4]; ii.Y = ctm[5]; ii.W = ctm[0]; ii.H = ctm[3]; pr.Imgs.Add(ii);
              }
            }
          }
          break;
      }
      args.Clear();
    }
    return pr;
  }

  static void Show(List<object> items, FontInfo f, double fs, double tc, double tw, double th, double rise, ref double[] tm, double[] ctm, PageResult pr) {
    StringBuilder sb = new StringBuilder();
    double[] trm0 = Mul(Mul(new double[] { fs * th, 0, 0, fs, 0, rise }, tm), ctm);
    double x0 = trm0[4], y0 = trm0[5];
    double effFs = Math.Sqrt(trm0[2] * trm0[2] + trm0[3] * trm0[3]);
    foreach (object it in items) {
      byte[] bytes = it as byte[];
      if (bytes != null) {
        int step = f.TwoByte ? 2 : 1;
        for (int i = 0; i + step <= bytes.Length; i += step) {
          int code = step == 2 ? (bytes[i] << 8) | bytes[i + 1] : bytes[i];
          string g; if (!f.Map.TryGetValue(code, out g)) g = step == 1 ? ((char)code).ToString() : "?";
          sb.Append(g);
          double w; if (!f.W.TryGetValue(code, out w)) w = f.TwoByte ? f.DW : 500;
          double tx = (w / 1000.0 * fs + tc + (step == 1 && code == 32 ? tw : 0)) * th;
          tm = Mul(new double[] { 1, 0, 0, 1, tx, 0 }, tm);
        }
      } else if (it is double) {
        double adj = (double)it;
        double tx = -adj / 1000.0 * fs * th;
        if (adj < -180 && sb.Length > 0 && sb[sb.Length - 1] != ' ') sb.Append(' ');
        tm = Mul(new double[] { 1, 0, 0, 1, tx, 0 }, tm);
      }
    }
    double[] trm1 = Mul(Mul(new double[] { fs * th, 0, 0, fs, 0, rise }, tm), ctm);
    if (sb.Length == 0) return;
    TItem ti = new TItem(); ti.X = x0; ti.Y = y0; ti.Fs = effFs; ti.W = trm1[4] - x0; ti.T = sb.ToString(); ti.Mono = f.Mono;
    pr.Text.Add(ti);
  }

  // ---- layout: group into lines ----
  class Line { public double Y; public double Fs; public List<TItem> Items = new List<TItem>(); public List<IItem> Imgs = new List<IItem>(); }

  static string LineText(Line ln) {
    List<TItem> its = ln.Items.OrderBy(t => t.X).ToList();
    StringBuilder sb = new StringBuilder(); double endX = 0; bool first = true; double mainFs = ln.Fs;
    TItem prev = null;
    foreach (TItem t in its) {
      string txt = t.T;
      bool small = t.Fs < mainFs * 0.82;
      if (small && !first) {
        double dy = t.Y - ln.Y;
        string mark = dy > 0.15 * mainFs ? "^" : (dy < -0.15 * mainFs ? "_" : "");
        if (mark != "") txt = mark + (txt.Length > 1 ? "(" + txt + ")" : txt);
      }
      if (!first) {
        double gap = t.X - endX;
        if (ln.Items.Any(z => z.Mono) && t.Mono) {
          int sp = (int)Math.Round(gap / (0.6 * t.Fs)); if (sp > 0) sb.Append(' ', Math.Min(sp, 40));
        } else if (gap > 2.2 * mainFs) sb.Append("  |  ");
        else if (gap > 0.12 * mainFs && !(sb.Length > 0 && sb[sb.Length - 1] == ' ') && !(txt.Length > 0 && txt[0] == ' ')) sb.Append(' ');
      }
      sb.Append(txt);
      endX = Math.Max(endX, t.X + t.W); first = false; prev = t;
    }
    return sb.ToString().TrimEnd();
  }

  public static List<int> PageIds() { return Pages(); }

  public static string PageToText(int pageId, int pageNo, Dictionary<int, string> imgNames, HashSet<int> skip, out List<int> usedImgs) {
    PageResult pr = ReadPage(pageId);
    usedImgs = new List<int>();
    List<TItem> items = pr.Text.OrderByDescending(t => t.Y).ThenBy(t => t.X).ToList();
    List<Line> lines = new List<Line>();
    foreach (TItem t in items) {
      Line best = null;
      foreach (Line ln in lines) {
        if (Math.Abs(t.Y - ln.Y) <= 0.55 * Math.Max(ln.Fs, t.Fs) && (t.Fs >= 0.6 * ln.Fs || Math.Abs(t.Y - ln.Y) < 0.4 * ln.Fs)) { best = ln; break; }
      }
      if (best == null) { best = new Line(); best.Y = t.Y; best.Fs = t.Fs; lines.Add(best); }
      else if (t.Fs > best.Fs) { best.Fs = t.Fs; }
      best.Items.Add(t);
    }
    // re-anchor line baseline to its largest item
    foreach (Line ln in lines) { TItem big = ln.Items.OrderByDescending(z => z.Fs).First(); ln.Y = big.Y; ln.Fs = big.Fs; }
    lines = lines.OrderByDescending(l => l.Y).ToList();
    StringBuilder sb = new StringBuilder();
    sb.AppendLine("=== PAGE " + pageNo + " ===");
    List<IItem> imgs = pr.Imgs.Where(i => !skip.Contains(i.ObjId)).OrderByDescending(i => i.Y + Math.Max(i.H, 0)).ToList();
    int ii = 0;
    foreach (Line ln in lines) {
      while (ii < imgs.Count && (imgs[ii].Y + Math.Max(imgs[ii].H, 0)) >= ln.Y) { string nm; imgNames.TryGetValue(imgs[ii].ObjId, out nm); sb.AppendLine("[IMG " + (nm ?? ("obj" + imgs[ii].ObjId)) + "]"); usedImgs.Add(imgs[ii].ObjId); ii++; }
      sb.AppendLine(LineText(ln));
    }
    while (ii < imgs.Count) { string nm; imgNames.TryGetValue(imgs[ii].ObjId, out nm); sb.AppendLine("[IMG " + (nm ?? ("obj" + imgs[ii].ObjId)) + "]"); usedImgs.Add(imgs[ii].ObjId); ii++; }
    return sb.ToString();
  }

  public static Dictionary<int, int> ImageUse(List<int> pages) {
    Dictionary<int, int> use = new Dictionary<int, int>();
    foreach (int p in pages) { PageResult pr = ReadPage(p); foreach (int id in pr.Imgs.Select(i => i.ObjId).Distinct()) { int c; use.TryGetValue(id, out c); use[id] = c + 1; } }
    return use;
  }

  public static string SaveImage(int id, string dir, string baseName) {
    PObj o = objs[id]; string d = o.Dict;
    int w = 0, h = 0; Match mw = Regex.Match(d, @"/Width\s+(\d+)"), mh = Regex.Match(d, @"/Height\s+(\d+)");
    if (mw.Success) w = int.Parse(mw.Groups[1].Value); if (mh.Success) h = int.Parse(mh.Groups[1].Value);
    if (d.Contains("DCTDecode")) { string p = Path.Combine(dir, baseName + ".jpg"); File.WriteAllBytes(p, o.Raw); return p + "|" + w + "x" + h; }
    byte[] raw = Decoded(o);
    int bpc = 8; Match mb = Regex.Match(d, @"/BitsPerComponent\s+(\d+)"); if (mb.Success) bpc = int.Parse(mb.Groups[1].Value);
    bool gray = d.Contains("DeviceGray"); int comps = gray ? 1 : 3;
    Match pred = Regex.Match(d, @"/Predictor\s+(\d+)");
    if (pred.Success && int.Parse(pred.Groups[1].Value) >= 10) {
      int rowLen = w * comps * bpc / 8; int bpp = Math.Max(1, comps * bpc / 8);
      byte[] outb = new byte[h * rowLen]; byte[] prev = new byte[rowLen]; int ip = 0;
      for (int y = 0; y < h && ip < raw.Length; y++) {
        int ft = raw[ip++]; byte[] cur = new byte[rowLen]; Array.Copy(raw, ip, cur, 0, Math.Min(rowLen, raw.Length - ip)); ip += rowLen;
        for (int x = 0; x < rowLen; x++) {
          int a = x >= bpp ? cur[x - bpp] : 0, b2 = prev[x], c2 = x >= bpp ? prev[x - bpp] : 0, v = cur[x];
          if (ft == 1) v += a; else if (ft == 2) v += b2; else if (ft == 3) v += (a + b2) / 2;
          else if (ft == 4) { int p0 = a + b2 - c2, pa = Math.Abs(p0 - a), pb = Math.Abs(p0 - b2), pc = Math.Abs(p0 - c2); v += (pa <= pb && pa <= pc) ? a : (pb <= pc ? b2 : c2); }
          cur[x] = (byte)(v & 255);
        }
        Array.Copy(cur, 0, outb, y * rowLen, rowLen); prev = cur;
      }
      raw = outb;
    }
    if (bpc != 8 || w == 0 || h == 0 || raw.Length < w * h * comps) return null;
    using (Bitmap bmp = new Bitmap(w, h, PixelFormat.Format24bppRgb)) {
      int idx = 0;
      for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
        int r, g, b; if (gray) { r = g = b = raw[idx++]; } else { r = raw[idx++]; g = raw[idx++]; b = raw[idx++]; }
        bmp.SetPixel(x, y, Color.FromArgb(r, g, b));
      }
      string p = Path.Combine(dir, baseName + ".png"); bmp.Save(p, ImageFormat.Png); return p + "|" + w + "x" + h;
    }
  }

  public static string DumpItems(int pageId, int maxN) {
    PageResult pr = ReadPage(pageId); StringBuilder sb = new StringBuilder(); int n = 0;
    foreach (TItem t in pr.Text.OrderByDescending(z => z.Y).ThenBy(z => z.X)) { sb.AppendLine(t.X.ToString("0.00") + " y=" + t.Y.ToString("0.00") + " fs=" + t.Fs.ToString("0.0") + " w=" + t.W.ToString("0.00") + " [" + t.T + "]"); if (++n >= maxN) break; }
    return sb.ToString();
  }

  public static string DumpContent(int pageId) {
    PObj po = objs[pageId]; StringBuilder content = new StringBuilder();
    Match cm = Regex.Match(po.Dict, @"/Contents\s*(\[(.*?)\]|(\d+)\s+\d+\s+R)", RegexOptions.Singleline);
    if (cm.Success) {
      string refs = cm.Groups[2].Success ? cm.Groups[2].Value : (cm.Groups[3].Value + " 0 R");
      foreach (Match r in Regex.Matches(refs, @"(\d+)\s+\d+\s+R")) { PObj c; if (objs.TryGetValue(int.Parse(r.Groups[1].Value), out c)) { content.Append(S(Decoded(c))); content.Append('\n'); } }
    }
    return content.ToString();
  }

  public static string ImageInfo(int id) { PObj o = objs[id]; return o.Dict.Replace("\r", " ").Replace("\n", " "); }
  public static PObj Get(int id) { return objs[id]; }
}
