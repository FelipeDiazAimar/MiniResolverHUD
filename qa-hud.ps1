# QA HUD - solo texto flotante abajo-izquierda (alpha real, sin fondo ni sombra). Ctrl+B muestra/oculta.
$mtx = New-Object System.Threading.Mutex($false, "QA-OpenCode-HUD")
if (-not $mtx.WaitOne(0)) { exit }
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$hudRefs = @([System.Windows.Forms.Form].Assembly.Location, [System.Drawing.Bitmap].Assembly.Location)
Add-Type -ReferencedAssemblies $hudRefs -TypeDefinition @"
using System;
using System.Windows.Forms;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Text;
using System.Runtime.InteropServices;
public static class HudWin32 {
  [DllImport("user32.dll")] public static extern bool RegisterHotKey(IntPtr h,int id,uint m,uint v);
  [DllImport("user32.dll")] public static extern bool UnregisterHotKey(IntPtr h,int id);
  [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h,int n);
  [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr h,int n,int v);
  [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr h);
  [DllImport("user32.dll")] public static extern int ReleaseDC(IntPtr h, IntPtr dc);
  [DllImport("user32.dll")] public static extern bool UpdateLayeredWindow(IntPtr h, IntPtr dstDc, ref Point pos, ref Size size, IntPtr srcDc, ref Point src, int key, ref BlendFn blend, int flags);
  [DllImport("gdi32.dll")] public static extern IntPtr CreateCompatibleDC(IntPtr dc);
  [DllImport("gdi32.dll")] public static extern bool DeleteDC(IntPtr dc);
  [DllImport("gdi32.dll")] public static extern IntPtr SelectObject(IntPtr dc, IntPtr o);
  [DllImport("gdi32.dll")] public static extern bool DeleteObject(IntPtr o);
  [DllImport("gdi32.dll")] public static extern IntPtr CreateDIBSection(IntPtr hdc, ref BitmapHead bh, uint usage, out IntPtr bits, IntPtr sec, uint off);
  [StructLayout(LayoutKind.Sequential, Pack=1)]
  public struct BlendFn { public byte Op; public byte Flags; public byte Alpha; public byte Format; }
  [StructLayout(LayoutKind.Sequential)]
  public struct BitmapHead {
    public uint biSize; public int biWidth; public int biHeight;
    public ushort biPlanes; public ushort biBitCount;
    public uint biCompression; public uint biSizeImage;
    public int biXP; public int biYP;
    public uint biClrUsed; public uint biClrImp;
  }
  public static void PaintText(IntPtr hwnd, string text, Font font, int maxW, int alpha) {
    Bitmap m = new Bitmap(1, 1, PixelFormat.Format32bppArgb);
    Graphics g0 = Graphics.FromImage(m);
    SizeF sz = g0.MeasureString(text, font, maxW);
    g0.Dispose(); m.Dispose();
    int w = (int)System.Math.Ceiling(sz.Width) + 8;
    int h = (int)System.Math.Ceiling(sz.Height) + 8;
    if (w < 1) w = 1; if (h < 1) h = 1;
    BitmapHead bh = new BitmapHead();
    bh.biSize = 40;
    bh.biWidth = w;
    bh.biHeight = -h;
    bh.biPlanes = 1;
    bh.biBitCount = 32;
    bh.biCompression = 0;
    IntPtr scr = GetDC(IntPtr.Zero);
    IntPtr mem = CreateCompatibleDC(scr);
    IntPtr bits;
    IntPtr hBmp = CreateDIBSection(mem, ref bh, 0, out bits, IntPtr.Zero, 0);
    IntPtr old = SelectObject(mem, hBmp);
    Graphics g = Graphics.FromHdc(mem);
    g.TextRenderingHint = TextRenderingHint.AntiAlias;
    using (SolidBrush fg = new SolidBrush(Color.FromArgb(alpha, 255, 255, 255))) {
      RectangleF r = new RectangleF(2, 2, maxW, h);
      g.DrawString(text, font, fg, r);
    }
    g.Dispose();
    Rectangle wa = Screen.PrimaryScreen.WorkingArea;
    Point pos = new Point(wa.Left + 4, wa.Bottom - h - 4);
    Size size = new Size(w, h);
    Point src = new Point(0, 0);
    BlendFn b = new BlendFn();
    b.Op = 0; b.Flags = 0; b.Alpha = 255; b.Format = 1;
    UpdateLayeredWindow(hwnd, scr, ref pos, ref size, mem, ref src, 0, ref b, 2);
    SelectObject(mem, old);
    DeleteObject(hBmp);
    DeleteDC(mem);
    ReleaseDC(IntPtr.Zero, scr);
  }
}
public class HudHotkey : NativeWindow, IDisposable {
  public event System.Action<int> Key;
  public bool RegOk = false;
  public HudHotkey() {
    CreateHandle(new CreateParams());
    bool a = HudWin32.RegisterHotKey(Handle,1,0x0002,0x42);
    bool b = HudWin32.RegisterHotKey(Handle,2,0x0002,0xDB);
    bool c = HudWin32.RegisterHotKey(Handle,3,0x0006,0xDB);
    RegOk = a && b && c;
  }
  protected override void WndProc(ref Message m) {
    if (m.Msg == 0x0312) { System.Action<int> h = Key; if (h != null) h(m.WParam.ToInt32()); }
    base.WndProc(ref m);
  }
  public void Dispose() { try { HudWin32.UnregisterHotKey(Handle,1); HudWin32.UnregisterHotKey(Handle,2); HudWin32.UnregisterHotKey(Handle,3); } catch {} try { DestroyHandle(); } catch {} }
}
"@
"$(Get-Date -Format o) hud csharp ok" | Out-File "$env:TEMP\qa-hud.log" -Append -Encoding utf8

$hudFile = "$env:TEMP\qa-hud.txt"
$script:cur = ""
$script:alpha = 255

$f = New-Object System.Windows.Forms.Form
$f.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$f.ShowInTaskbar = $false
$f.TopMost = $true
$f.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$f.Size = New-Object System.Drawing.Size(1, 1)

$h = $f.Handle
$ex = [HudWin32]::GetWindowLong($h, -20)
[HudWin32]::SetWindowLong($h, -20, ($ex -bor 0x80000 -bor 0x20 -bor 0x08000000)) | Out-Null

$fname = "SF Pro Text"
try { [void](New-Object System.Drawing.FontFamily($fname)) } catch { $fname = "Segoe UI" }
$font = New-Object System.Drawing.Font($fname, 8, [System.Drawing.FontStyle]::Regular)
"$(Get-Date -Format o) hud font=$fname" | Out-File "$env:TEMP\qa-hud.log" -Append -Encoding utf8

$hk = New-Object HudHotkey
"$(Get-Date -Format o) hud start pid=$PID regok=$($hk.RegOk)" | Out-File "$env:TEMP\qa-hud.log" -Append -Encoding utf8
$hk.add_Key({
  param($id)
  try {
    if ($id -eq 1) {
      "$(Get-Date -Format o) toggle visible-antes=$($f.Visible)" | Out-File "$env:TEMP\qa-hud.log" -Append -Encoding utf8
      if ($f.Visible) { $f.Hide() }
      elseif ($script:cur -ne "") { $f.Show(); [HudWin32]::PaintText($f.Handle, $script:cur, $font, 560, $script:alpha) }
    } elseif ($id -eq 2) {
      $script:alpha = [Math]::Max(40, $script:alpha - 25)
      if ($script:cur -ne "") { [HudWin32]::PaintText($f.Handle, $script:cur, $font, 560, $script:alpha) }
      "$(Get-Date -Format o) alpha=$script:alpha" | Out-File "$env:TEMP\qa-hud.log" -Append -Encoding utf8
    } elseif ($id -eq 3) {
      $script:alpha = [Math]::Min(255, $script:alpha + 25)
      if ($script:cur -ne "") { [HudWin32]::PaintText($f.Handle, $script:cur, $font, 560, $script:alpha) }
      "$(Get-Date -Format o) alpha=$script:alpha" | Out-File "$env:TEMP\qa-hud.log" -Append -Encoding utf8
    }
  } catch {}
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500
$timer.add_Tick({
  try {
    if (Test-Path $hudFile) {
      $t = (Get-Content $hudFile -Raw -ErrorAction SilentlyContinue)
      if ($null -ne $t) { $t = $t.Trim() } else { $t = "" }
      if ($t -ne "" -and $t -ne $script:cur) {
        $script:cur = $t
        [HudWin32]::PaintText($f.Handle, $t, $font, 560, $script:alpha)
        if (-not $f.Visible) { $f.Show() }
      }
    }
  } catch {}
})
$timer.Start()
[System.Windows.Forms.Application]::Run()
