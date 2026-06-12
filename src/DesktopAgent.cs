using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Windows.Forms;

class DesktopAgent
{
    [DllImport("user32.dll")]
    static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")]
    static extern bool GetCursorPos(out POINT lpPoint);
    [DllImport("user32.dll")]
    static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);
    [DllImport("user32.dll")]
    static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    [DllImport("user32.dll")]
    static extern short VkKeyScan(char ch);
    [DllImport("user32.dll")]
    static extern IntPtr GetDC(IntPtr hwnd);
    [DllImport("user32.dll")]
    static extern int ReleaseDC(IntPtr hwnd, IntPtr hdc);
    [DllImport("gdi32.dll")]
    static extern bool BitBlt(IntPtr hdcDest, int xDest, int yDest, int w, int h, IntPtr hdcSrc, int xSrc, int ySrc, uint rop);

    [StructLayout(LayoutKind.Sequential)]
    struct POINT { public int X; public int Y; }

    const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
    const uint MOUSEEVENTF_LEFTUP = 0x0004;
    const uint MOUSEEVENTF_RIGHTDOWN = 0x0008;
    const uint MOUSEEVENTF_RIGHTUP = 0x0010;
    const uint KEYEVENTF_KEYDOWN = 0x0000;
    const uint KEYEVENTF_KEYUP = 0x0002;
    const uint SRCCOPY = 0x00CC0020;

    static Dictionary<string, byte> keyMap = new Dictionary<string, byte>
    {
        {"Enter",0x0D},{"Tab",0x09},{"Escape",0x1B},{"Esc",0x1B},
        {"Space",0x20},{"Backspace",0x08},{"Delete",0x2E},{"Insert",0x2D},
        {"Home",0x24},{"End",0x23},{"PageUp",0x21},{"PageDown",0x22},
        {"Up",0x26},{"Down",0x28},{"Left",0x25},{"Right",0x27},
        {"F1",0x70},{"F2",0x71},{"F3",0x72},{"F4",0x73},{"F5",0x74},
        {"F6",0x75},{"F7",0x76},{"F8",0x77},{"F9",0x78},{"F10",0x79},
        {"F11",0x7A},{"F12",0x7B},
        {"Ctrl",0x11},{"Alt",0x12},{"Shift",0x10},{"Win",0x5B}
    };

    static string baseDir;
    static string cmdDir;

    static void Main(string[] args)
    {
        baseDir = AppDomain.CurrentDomain.BaseDirectory;
        cmdDir = Path.Combine(baseDir, "commands");
        if (!Directory.Exists(cmdDir)) Directory.CreateDirectory(cmdDir);

        Console.WriteLine("Desktop Agent ready. Watching: " + cmdDir);

        while (true)
        {
            try
            {
                var files = Directory.GetFiles(cmdDir, "*.cmd");
                foreach (var file in files)
                {
                    try
                    {
                        string content = File.ReadAllText(file, Encoding.UTF8);
                        string result = ProcessCommand(content.Trim());
                        string resultFile = file.Replace(".cmd", ".result");
                        File.WriteAllText(resultFile, result, Encoding.UTF8);
                        File.Delete(file);
                    }
                    catch (Exception ex)
                    {
                        try { File.WriteAllText(file.Replace(".cmd", ".result"), "ERROR:" + ex.Message); File.Delete(file); } catch { }
                    }
                }
            }
            catch { }
            Thread.Sleep(200);
        }
    }

    static string ProcessCommand(string cmd)
    {
        var parts = cmd.Split(new[] { '|' }, 2);
        string action = parts[0];
        string paramStr = parts.Length > 1 ? parts[1] : "";
        var ps = paramStr.Split(',');
        switch (action)
        {
            case "SCREENSHOT": return DoScreenshot(ps);
            case "MOUSEPOS": return DoMousePos();
            case "MOUSEMOVE": return DoMouseMove(ps);
            case "CLICK": return DoClick(ps);
            case "DBLCLICK": return DoDblClick(ps);
            case "KEY": return DoKey(ps);
            case "TYPE": return DoType(ps);
            case "SCREENSIZE": return DoScreenSize();
            case "PING": return "PONG";
            default: return "ERROR:Unknown command";
        }
    }

    static string DoScreenshot(string[] ps)
    {
        string path = ps.Length > 0 ? ps[0].Trim() : "screenshot.png";
        int x = 0, y = 0, w = -1, h = -1;
        if (ps.Length > 1) int.TryParse(ps[1], out x);
        if (ps.Length > 2) int.TryParse(ps[2], out y);
        if (ps.Length > 3) int.TryParse(ps[3], out w);
        if (ps.Length > 4) int.TryParse(ps[4], out h);
        var screen = Screen.PrimaryScreen;
        if (w <= 0) w = screen.Bounds.Width;
        if (h <= 0) h = screen.Bounds.Height;
        if (!Path.IsPathRooted(path)) path = Path.Combine(baseDir, path);
        using (var bmp = new Bitmap(w, h))
        {
            using (var g = Graphics.FromImage(bmp))
            {
                IntPtr hdcDest = g.GetHdc();
                IntPtr hdcSrc = GetDC(IntPtr.Zero);
                BitBlt(hdcDest, 0, 0, w, h, hdcSrc, x, y, SRCCOPY);
                g.ReleaseHdc(hdcDest);
                ReleaseDC(IntPtr.Zero, hdcSrc);
            }
            var dir = Path.GetDirectoryName(path);
            if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir)) Directory.CreateDirectory(dir);
            bmp.Save(path, ImageFormat.Png);
        }
        return "OK:" + path;
    }

    static string DoMousePos() { POINT p; GetCursorPos(out p); return string.Format("OK:{0},{1}", p.X, p.Y); }
    static string DoMouseMove(string[] ps) { SetCursorPos(int.Parse(ps[0]), int.Parse(ps[1])); return "OK"; }

    static string DoClick(string[] ps)
    {
        string btn = ps.Length > 0 ? ps[0].Trim().ToLower() : "left";
        if (ps.Length >= 3) { SetCursorPos(int.Parse(ps[1]), int.Parse(ps[2])); Thread.Sleep(30); }
        uint down = btn == "right" ? MOUSEEVENTF_RIGHTDOWN : MOUSEEVENTF_LEFTDOWN;
        uint up = btn == "right" ? MOUSEEVENTF_RIGHTUP : MOUSEEVENTF_LEFTUP;
        mouse_event(down, 0, 0, 0, UIntPtr.Zero); Thread.Sleep(30); mouse_event(up, 0, 0, 0, UIntPtr.Zero);
        return "OK";
    }

    static string DoDblClick(string[] ps)
    {
        if (ps.Length >= 2) { SetCursorPos(int.Parse(ps[0]), int.Parse(ps[1])); Thread.Sleep(30); }
        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, UIntPtr.Zero); Thread.Sleep(30);
        mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, UIntPtr.Zero); Thread.Sleep(50);
        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, UIntPtr.Zero); Thread.Sleep(30);
        mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, UIntPtr.Zero);
        return "OK";
    }

    static string DoKey(string[] ps)
    {
        string key = ps[0].Trim();
        List<string> mods = new List<string>();
        for (int i = 1; i < ps.Length; i++) if (ps[i].Trim().Length > 0) mods.Add(ps[i].Trim());
        foreach (var m in mods) if (keyMap.ContainsKey(m)) keybd_event(keyMap[m], 0, KEYEVENTF_KEYDOWN, UIntPtr.Zero);
        byte vk;
        if (!keyMap.TryGetValue(key, out vk)) { if (key.Length == 1) vk = (byte)(VkKeyScan(key[0]) & 0xFF); else return "ERROR:Unknown key"; }
        keybd_event(vk, 0, KEYEVENTF_KEYDOWN, UIntPtr.Zero); Thread.Sleep(30);
        keybd_event(vk, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
        mods.Reverse();
        foreach (var m in mods) if (keyMap.ContainsKey(m)) keybd_event(keyMap[m], 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
        return "OK";
    }

    static string DoType(string[] ps) { string text = string.Join(",", ps); SendKeys.SendWait(text); return "OK"; }
    static string DoScreenSize() { var s = Screen.PrimaryScreen; return string.Format("OK:{0},{1}", s.Bounds.Width, s.Bounds.Height); }
}
