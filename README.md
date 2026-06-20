# 桌面代理 (Desktop Agent)

Windows 桌面自动化代理 — 支持鼠标、键盘、屏幕截图等操作，提供 C# 控制台程序与 PowerShell 模块两种使用方式。

## 项目结构

```
桌面代理/
├── bin/                # 编译后的可执行文件
│   └── DesktopAgent.exe
├── src/                # 源代码
│   ├── DesktopAgent.cs # C# 桌面代理程序（主程序）
│   └── modules/        # PowerShell 功能模块
│       ├── screen.ps1      # 屏幕截图
│       ├── mouse.ps1       # 鼠标控制
│       └── keyboard.ps1    # 键盘控制
├── agent/              # 代理脚本
│   ├── agent.ps1           # PowerShell 代理入口（加载模块、提供 Invoke-AgentAction）
│   └── agent_client.ps1    # 客户端脚本（通过 C# agent 的 cmd 文件协议通信）
├── scripts/            # 辅助脚本
│   ├── build.ps1           # 编译脚本
│   ├── test_com.ps1        # COM 功能测试
│   ├── test_control.ps1    # .NET Forms 控制测试
│   └── task_screenshot.ps1 # 全屏截图任务
└── README.md
```

## 使用方式

### 1. C# 桌面代理（DesktopAgent.exe）

```powershell
# 启动代理（监控 commands 目录）
.\bin\DesktopAgent.exe

# 在另一个终端中通过命令文件与其通信
.\agent\agent_client.ps1 -Action screenshot
.\agent\agent_client.ps1 -Action mousepos
.\agent\agent_client.ps1 -Action click -Arg1 left -Arg2 500 -Arg3 300
.\agent\agent_client.ps1 -Action type -Arg1 "Hello World"
```

支持的指令：
| 指令 | 参数 | 说明 |
|------|------|------|
| `SCREENSHOT` | path,x,y,w,h | 截图 |
| `MOUSEPOS` | | 获取鼠标位置 |
| `MOUSEMOVE` | x,y | 移动鼠标 |
| `CLICK` | button,x,y | 点击（left/right） |
| `DBLCLICK` | x,y | 双击 |
| `KEY` | key,modifiers | 按键（支持 Ctrl/Alt/Shift/Win 组合） |
| `TYPE` | text | 输入文本 |
| `SCREENSIZE` | | 获取屏幕尺寸 |
| `PING` | | 健康检查 |

### 2. PowerShell 代理模块

```powershell
# 加载模块
. .\agent\agent.ps1

# 使用命令
Take-Screenshot -OutputPath "test.png"
Move-Mouse -X 100 -Y 100
Click-Mouse -Button Left
Send-Key -Key "F5"
Send-Key -Key "C" -Modifiers @("Ctrl")
Type-Text -Text "Hello World"
```

## 编译

```powershell
.\scripts\build.ps1
```

编译要求：.NET Framework 4.x 或 Mono，C# 编译器（csc）。

## 系统要求

- Windows 操作系统
- PowerShell 5.0+
- .NET Framework 4.x（运行时）
- C# 编译器（仅编译时需要）
