using System;
using System.Collections.Generic;
using System.Drawing.Drawing2D;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Windows.Forms;
class DesktopAgent
{
    [DllImport("user32.dll")] static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] static extern bool GetCursorPos(out POINT p);
    [DllImport("user32.dll")] static extern void mouse_event(uint f,uint dx,uint dy,uint d,UIntPtr e);
    [DllImport("user32.dll")] static extern void keybd_event(byte v,byte s,uint f,UIntPtr e);
    [DllImport("user32.dll")] static extern short VkKeyScan(char c);
    [DllImport("user32.dll")] static extern IntPtr GetDC(IntPtr h);
    [DllImport("user32.dll")] static extern int ReleaseDC(IntPtr h,IntPtr d);
    [DllImport("gdi32.dll")] static extern bool BitBlt(IntPtr d,int x,int y,int w,int h,IntPtr s,int sx,int sy,uint r);
    [DllImport("user32.dll")] static extern IntPtr OpenInputDesktop(uint f,bool i,uint a);
    [DllImport("user32.dll")] static extern bool SetThreadDesktop(IntPtr h);
    [DllImport("user32.dll")] static extern bool CloseDesktop(IntPtr h);
    [DllImport("user32.dll",SetLastError=true)] static extern uint SendInput(uint n,INPUT[] p,int sz);
    const uint IM=0,IK=1,LD=2,LU=4,RD=8,RU=0x10,MV=1,AB=0x8000;
    const uint KD=0,KU=2,UNI=4,SRC=0x00CC0020;
    struct POINT {public int X,Y;}
    struct INPUT {public uint t;public InputUnion u;}
    [StructLayout(LayoutKind.Explicit)] struct InputUnion {[FieldOffset(0)]public MOUSEINPUT m;[FieldOffset(0)]public KEYBDINPUT k;}
    struct MOUSEINPUT{public int dx,dy;public uint d,f,t;public UIntPtr e;}
    struct KEYBDINPUT{public ushort v,s;public uint f,t;public UIntPtr e;}
    static Dictionary<string,byte> keyMap=new Dictionary<string,byte>{
        {"Enter",0x0D},{"Tab",0x09},{"Escape",0x1B},{"Esc",0x1B},{"Space",0x20},
        {"Backspace",0x08},{"Delete",0x2E},{"Insert",0x2D},{"Home",0x24},{"End",0x23},
        {"PageUp",0x21},{"PageDown",0x22},{"Up",0x26},{"Down",0x28},{"Left",0x25},{"Right",0x27},
        {"F1",0x70},{"F2",0x71},{"F3",0x72},{"F4",0x73},{"F5",0x74},{"F6",0x75},
        {"F7",0x76},{"F8",0x77},{"F9",0x78},{"F10",0x79},{"F11",0x7A},{"F12",0x7B},
        {"Ctrl",0x11},{"Alt",0x12},{"Shift",0x10},{"Win",0x5B}
    };
    static string baseDir,cmdDir;
    static IntPtr _hD=IntPtr.Zero;
    static bool _sw=false;
    static bool SwitchInput(){
        if(_sw)return true;
        IntPtr h=OpenInputDesktop(0,false,0x0002|0x0080|0x0100);
        if(h==IntPtr.Zero)h=OpenInputDesktop(0,false,0x0002|0x0080);
        if(h!=IntPtr.Zero&&SetThreadDesktop(h)){_hD=h;_sw=true;return true;}
        if(h!=IntPtr.Zero)CloseDesktop(h);
        return false;
    }
    static void SMI(int dx,int dy,uint f,uint d){
        INPUT i=new INPUT();i.t=IM;i.u.m=new MOUSEINPUT();
        i.u.m.dx=dx;i.u.m.dy=dy;i.u.m.d=d;i.u.m.f=f;i.u.m.t=0;i.u.m.e=UIntPtr.Zero;
        SendInput(1,new INPUT[]{i},Marshal.SizeOf(typeof(INPUT)));
    }
    static void SKI(ushort v,ushort s,uint f){
        INPUT i=new INPUT();i.t=IK;i.u.k=new KEYBDINPUT();
        i.u.k.v=v;i.u.k.s=s;i.u.k.f=f;i.u.k.t=0;i.u.k.e=UIntPtr.Zero;
        SendInput(1,new INPUT[]{i},Marshal.SizeOf(typeof(INPUT)));
    }
    static void LC(uint d,uint u){mouse_event(d,0,0,0,UIntPtr.Zero);Thread.Sleep(15);mouse_event(u,0,0,0,UIntPtr.Zero);}
    static void LK(byte v,uint f){keybd_event(v,0,f,UIntPtr.Zero);}
    static void MoveAbs(int x,int y){
        SwitchInput();
        var s=Screen.PrimaryScreen.Bounds;
        if(s.Width>1&&s.Height>1)SMI((x*65535)/(s.Width-1),(y*65535)/(s.Height-1),MV|AB,0);
        SetCursorPos(x,y);
    }
    static void DoClick(string b){
        uint d=b=="right"?RD:LD,u=b=="right"?RU:LU;
        SMI(0,0,d,0);Thread.Sleep(15);SMI(0,0,u,0);LC(d,u);
    }
    static void DoPress(byte v){
        SKI(v,0,KD);Thread.Sleep(15);SKI(v,0,KU);LK(v,KD);Thread.Sleep(10);LK(v,KU);
    }
    static void DoMod(byte v,bool down){
        uint f=down?KD:KU;SKI(v,0,f);LK(v,f);
    }
    static void SText(string t){
        SwitchInput();
        foreach(char c in t){
            if(c=='\r')continue;
            if(c=='\n'){DoPress((byte)Keys.Enter);continue;}
            INPUT i=new INPUT();i.t=IK;i.u.k=new KEYBDINPUT();
            i.u.k.v=0;i.u.k.s=(ushort)c;i.u.k.f=UNI;i.u.k.t=0;i.u.k.e=UIntPtr.Zero;
            SendInput(1,new INPUT[]{i},Marshal.SizeOf(typeof(INPUT)));Thread.Sleep(10);
            i.u.k.f=UNI|KU;SendInput(1,new INPUT[]{i},Marshal.SizeOf(typeof(INPUT)));
            short sc=VkKeyScan(c);
            if((sc&0xFF)!=0||c==' '){byte v=(byte)(sc&0xFF);LK(v,KD);Thread.Sleep(10);LK(v,KU);}
            Thread.Sleep(10);
        }
    }
    static void Main(string[] a){
        baseDir=AppDomain.CurrentDomain.BaseDirectory;
        cmdDir=Path.Combine(baseDir,"commands");
        if(!Directory.Exists(cmdDir))Directory.CreateDirectory(cmdDir);
        Console.WriteLine("Desktop Agent ready. Watching: "+cmdDir);
        while(true){
            try{
                foreach(string f in Directory.GetFiles(cmdDir,"*.cmd")){
                    try{
                        string c=File.ReadAllText(f,Encoding.UTF8);
                        string r=ProcessCommand(c.Trim());
                        string rf=f.Replace(".cmd",".result");
                        File.WriteAllText(rf,r,Encoding.UTF8);File.Delete(f);
                    }catch(Exception ex){try{File.WriteAllText(f.Replace(".cmd",".result"),"ERROR:"+ex.Message);File.Delete(f);}catch{}}
                }
            }catch{}Thread.Sleep(200);
        }
    }
    static string ProcessCommand(string cmd){
        string[] p=cmd.Split(new char[]{'|'},2);
        string a=p[0],ps=p.Length>1?p[1]:"",q=ps;
        string[] arr=q.Split(',');
        switch(a){
            case"SCREENSHOT":return DoScreenshot(arr);
            case"MOUSEPOS":return DoMousePos();
            case"MOUSEMOVE":return DoMouseMove(arr);
            case"CLICK":return DoClick(arr);
            case"DBLCLICK":return DoDblClick(arr);
            case"KEY":return DoKey(arr);
            case"TYPE":return DoType(arr);
            case"SCREENSIZE":return DoScreenSize();
            case"PING":return"PONG";
            default:return"ERROR:Unknown command";
        }
    }
    static string DoScreenshot(string[] ps){
        string path=ps.Length>0?ps[0].Trim():"screenshot.jpg";
        int x=0,y=0,w=-1,h=-1,q=40;
        float scale=0.5f;
        if(ps.Length>1)int.TryParse(ps[1],out x);
        if(ps.Length>2)int.TryParse(ps[2],out y);
        if(ps.Length>3)int.TryParse(ps[3],out w);
        if(ps.Length>4)int.TryParse(ps[4],out h);
        if(ps.Length>5)int.TryParse(ps[5],out q);
        if(ps.Length>6)float.TryParse(ps[6],out scale);
        Screen sc=Screen.PrimaryScreen;
        if(w<=0)w=sc.Bounds.Width;if(h<=0)h=sc.Bounds.Height;
        if(!Path.IsPathRooted(path))path=Path.Combine(baseDir,path);
        IntPtr hd=OpenInputDesktop(0,false,0x0002|0x0080);
        if(hd!=IntPtr.Zero)SetThreadDesktop(hd);
        try{
            using(Bitmap src=new Bitmap(w,h)){
                try{using(Graphics g=Graphics.FromImage(src))g.CopyFromScreen(x,y,0,0,new Size(w,h));}
                catch{using(Graphics g=Graphics.FromImage(src)){IntPtr dd=g.GetHdc();IntPtr ss=GetDC(IntPtr.Zero);if(ss!=IntPtr.Zero){BitBlt(dd,0,0,w,h,ss,x,y,SRC);ReleaseDC(IntPtr.Zero,ss);}g.ReleaseHdc(dd);}}
                string dir=Path.GetDirectoryName(path);
                if(!string.IsNullOrEmpty(dir)&&!Directory.Exists(dir))Directory.CreateDirectory(dir);
                ImageCodecInfo jc=null;
                foreach(ImageCodecInfo c in ImageCodecInfo.GetImageEncoders()){if(c.MimeType=="image/jpeg"){jc=c;break;}}
                EncoderParameters ep=new EncoderParameters(1);
                ep.Param[0]=new EncoderParameter(System.Drawing.Imaging.Encoder.Quality,(long)q);
                if(scale<1.0f&&scale>0.1f){
                    int sw=(int)(w*scale),sh=(int)(h*scale);
                    if(sw<1)sw=1;if(sh<1)sh=1;
                    using(Bitmap rs=new Bitmap(sw,sh)){
                        using(Graphics rg=Graphics.FromImage(rs)){
                            rg.InterpolationMode=InterpolationMode.HighQualityBicubic;
                            rg.DrawImage(src,0,0,sw,sh);
                        }
                        rs.Save(path,jc,ep);
                    }
                }else{
                    src.Save(path,jc,ep);
                }
            }
        }finally{if(hd!=IntPtr.Zero)CloseDesktop(hd);}
        return"OK:"+path;
    }
    static string DoMousePos(){SwitchInput();POINT p;GetCursorPos(out p);return string.Format("OK:{0},{1}",p.X,p.Y);}
    static string DoMouseMove(string[] ps){MoveAbs(int.Parse(ps[0]),int.Parse(ps[1]));return"OK";}
    static string DoClick(string[] ps){string b=ps.Length>0?ps[0].Trim().ToLower():"left";if(ps.Length>=3){MoveAbs(int.Parse(ps[1]),int.Parse(ps[2]));Thread.Sleep(30);}DoClick(b);return"OK";}
    static string DoDblClick(string[] ps){if(ps.Length>=2){MoveAbs(int.Parse(ps[0]),int.Parse(ps[1]));Thread.Sleep(30);}DoClick("left");Thread.Sleep(50);DoClick("left");return"OK";}
    static string DoKey(string[] ps){string k=ps[0].Trim();List<string>m=new List<string>();for(int i=1;i<ps.Length;i++)if(ps[i].Trim().Length>0)m.Add(ps[i].Trim());byte v;if(!keyMap.TryGetValue(k,out v)){if(k.Length==1)v=(byte)(VkKeyScan(k[0])&0xFF);else return"ERROR:Unknown key";}foreach(string x in m)if(keyMap.ContainsKey(x))DoMod(keyMap[x],true);DoPress(v);foreach(string x in m)if(keyMap.ContainsKey(x))DoMod(keyMap[x],false);return"OK";}
    static string DoType(string[] ps){string t=string.Join(",",ps);SText(t);return"OK";}
    static string DoScreenSize(){Screen s=Screen.PrimaryScreen;return string.Format("OK:{0},{1}",s.Bounds.Width,s.Bounds.Height);}
}
