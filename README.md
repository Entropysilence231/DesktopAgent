# DesktopAgent

> Windows 桌面自动化代理 — 截屏、识屏、鼠标控制、键盘控制。通过文件系统通信的轻量级后台进程。
>
> A lightweight Windows desktop automation agent for screenshot, screen recognition, mouse and keyboard control. Communicates via the filesystem.

---

## 功能 / Features

- **截屏** — 支持全屏、区域截屏，直接调用 Win32 GDI BitBlt
- **鼠标控制** — 移动、单击/双击（左/右/中键）、拖拽
- **键盘控制** — 按键、组合键（Ctrl+C / Alt+Tab）、文本输入
- **文件系统通信** — 监听 commands/ 目录的 .cmd 文件，异步处理并写入 .result 文件
- **纯后台运行** — 无窗口，无控制台输出，~16 MB 内存占用
- **两种工作模式** — 独立 DesktopAgent.exe 后台进程 + agent.ps1 PowerShell 脚本模式

---

## 快速开始 / Quick Start

### 方式一：后台进程（推荐用于 AI Agent 集成）

```cmd
# 启动后台进程（无窗口，常驻）
start /b bin\DesktopAgent.exe
# 通过客户端脚本发送指令
powershell -File scripts\agent_client.ps1 -Action screenshot
powershell -File scripts\agent_client.ps1 -Action mousepos
powershell -File scripts\agent_client.ps1 -Action click -Arg1 left -Arg2 500 -Arg3 300
powershell -File scripts\agent_client.ps1 -Action key -Arg1 Enter
# 停止进程
taskkill /f /im DesktopAgent.exe
```

### 方式二：PowerShell 脚本（即时使用）

```powershell
# 加载所有模块
. .\scripts\agent.ps1
# 截图
Take-Screenshot -OutputPath "screen.png"
# 鼠标操作
Get-MousePos
Move-Mouse -X 500 -Y 300
Click-Mouse -Button Left -X 500 -Y 300
Drag-Mouse -FromX 100 -FromY 100 -ToX 500 -ToY 500
# 键盘操作
Send-Key -Key Enter
Send-KeyCombo -Keys Ctrl, C
Type-Text -Text "Hello, World!"
```

---

## 通信协议 / Communication Protocol

DesktopAgent.exe 监听 commands/ 目录：

1. 客户端写入 commands/<id>.cmd 文件
2. Agent 每 200ms 扫描目录，处理 .cmd 文件
3. 处理后写入 .result 文件，删除 .cmd 文件
4. 客户端轮询读取 .result 文件

### 命令格式

```
ACTION|param1,param2,...
```

### 支持的命令

| 命令 | 参数 | 说明 |
|------|------|------|
| SCREENSHOT | path,x,y,w,h | 截屏，可指定区域 |
| MOUSEPOS | 无 | 获取鼠标位置 |
| MOUSEMOVE | x,y | 移动鼠标 |
| CLICK | button,x,y | 单击（left/right） |
| DBLCLICK | x,y | 双击 |
| KEY | key,mod1,mod2 | 按键，支持修饰键 |
| TYPE | text | 输入文本 |
| SCREENSIZE | 无 | 获取屏幕尺寸 |
| PING | 无 | 心跳检测 |

---

## 文件结构 / File Structure

```
DesktopAgent/
├── LICENSE
├── README.md
├── .gitignore
├── src/
│   └── DesktopAgent.cs     # C# 源码
├── scripts/
│   ├── agent.ps1           # 主代理脚本
│   ├── agent_client.ps1    # 文件队列客户端
│   ├── screen.ps1          # 截屏模块
│   ├── mouse.ps1           # 鼠标控制模块
│   ├── keyboard.ps1        # 键盘控制模块
│   ├── test_control.ps1    # .NET Forms 测试
│   ├── test_com.ps1        # COM 接口测试
│   └── task_screenshot.ps1 # 定时截图任务
├── bin/
│   └── DesktopAgent.exe    # 预编译二进制（10 KB）
└── examples/
    └── demo.cmd            # 命令文件示例
```

---

## 编译 / Build from Source

```cmd
csc /target:exe /reference:System.Windows.Forms.dll /reference:System.Drawing.dll src\DesktopAgent.cs
```

```powershell
Add-Type -TypeDefinition (Get-Content src\DesktopAgent.cs -Raw) -ReferencedAssemblies "System.Windows.Forms","System.Drawing" -OutputAssembly "bin\DesktopAgent.exe"
```

---

## License

MIT
