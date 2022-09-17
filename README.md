微软在 Windows 10 上新增了一项功能 Windows 聚焦 (Windows Spotlight)，它会自动随机下载并更换锁屏界面的壁纸 (Lockscreen)，让你每次打开电脑都有不一样的视觉享受。

这些高清锁屏壁纸往往都很精美，很多视觉冲击力十足，非常值得收藏。但很多同学想将这些壁纸设为桌面，却不知道怎样下载保存Win10的锁屏壁纸。实际上这些精美的图片都在你电脑上的缓存文件夹中，比如我的就在`C:\Users\Anymake\AppData\Local\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets`中，这些缓存文件没有后缀名，你只需要重命名加上.jpg就可以看到了。这些手动提取的教程各大网站都有介绍。

但是每次手动复制比较繁琐，我实现了一个自动化的将每天新更新的 Windows 聚焦 (Windows Spotlight) 图片设置为桌面壁纸的程序。本方法不需要单独安装任何软件，只需要 Windows 自带的Powershell 和任务计划程序就可以了。

## 一、编写自动提取并设置为壁纸的脚本

打开一个文本文件，复制以下代码，保存后缀为.ps1，命名为`SetWallPaperFromSpotlight.ps1`，然后右键“使用 powershell运行”就可以发现桌面壁纸已经被设置为了最新的图片。所有的聚焦图片都被复制到你自己的用户文件夹下的 Spotlight 文件夹。比如我的是在：`C:\Users\Anymake\Pictures\Spotlight`。这样你就有了一个手动提取并设置最新图片为桌面壁纸的方法。下面第二步介绍每天电脑自动设置的方法。

```powershell
# 将复制出来的缓存图片保存在下面的文件夹
add-type -AssemblyName System.Drawing
New-Item "$($env:USERPROFILE)\Pictures\Spotlight" -ItemType directory -Force;
New-Item "$($env:USERPROFILE)\Pictures\Spotlight\CopyAssets" -ItemType directory -Force;
New-Item "$($env:USERPROFILE)\Pictures\Spotlight\Horizontal" -ItemType directory -Force;
New-Item "$($env:USERPROFILE)\Pictures\Spotlight\Vertical" -ItemType directory -Force;
 
# 将横竖图片分别复制到对应的两个文件夹
foreach($file in (Get-Item "$($env:LOCALAPPDATA)\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets\*"))
{
    if ((Get-Item $file).length -lt 100kb) { continue }
    Copy-Item $file.FullName "$($env:USERPROFILE)\Pictures\Spotlight\CopyAssets\$($file.Name).jpg";
}
 
foreach($newfile in (Get-Item "$($env:USERPROFILE)\Pictures\Spotlight\CopyAssets\*"))
{
    $image = New-Object -comObject WIA.ImageFile;
    $image.LoadFile($newfile.FullName);
    if($image.Width.ToString() -eq "1920"){ Move-Item $newfile.FullName "$($env:USERPROFILE)\Pictures\Spotlight\Horizontal" -Force; }
    elseif($image.Width.ToString() -eq "1080"){ Move-Item $newfile.FullName "$($env:USERPROFILE)\Pictures\Spotlight\Vertical" -Force; }
}
 
# 壁纸设置函数
function Set-Wallpaper
{
    param(
        [Parameter(Mandatory=$true)]
        $Path,
 
        [ValidateSet('Center', 'Stretch')]
        $Style = 'Center'
    )
 
    Add-Type @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;
namespace Wallpaper
{
public enum Style : int
{
Center, Stretch
}
public class Setter {
public const int SetDesktopWallpaper = 20;
public const int UpdateIniFile = 0x01;
public const int SendWinIniChange = 0x02;
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
public static void SetWallpaper ( string path, Wallpaper.Style style ) {
SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);
switch( style )
{
case Style.Stretch :
key.SetValue(@"WallpaperStyle", "2") ;
key.SetValue(@"TileWallpaper", "0") ;
break;
case Style.Center :
key.SetValue(@"WallpaperStyle", "1") ;
key.SetValue(@"TileWallpaper", "0") ;
break;
}
key.Close();
}
}
}
"@
 
    [Wallpaper.Setter]::SetWallpaper( $Path, $Style )
}
 
 
$filePath = "$($env:USERPROFILE)\Pictures\Spotlight\Horizontal\*"
$file = Get-Item -Path $filePath | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
Set-Wallpaper -Path $file.FullName  
# echo $file.FullName
 
Remove-Item "$($env:USERPROFILE)\Pictures\Spotlight\CopyAssets\*";
#pause
```


其中设置桌面壁纸的代码参考自：http://www.pstips.net/powershell-change-wallpaper.html

提取windows聚焦的图片参考自：http://www.iplaysoft.com/save-win10-spotlight-wallpapers.html



## 二、利用windows自带的任务计划程序每天自动运行脚本

必须以管理员身份登录才能执行这些步骤。如果不是以管理员身份登录，则您仅能更改适用于您的用户帐户的设置。

1、由于windows默认的任务计划没有权限执行ps1脚本，因此首先需要用管理员运行Windows PowerShell

![img](https://img.arctee.cn/one/202209171717324.png)



2、输入 Set-ExecutionPolicy Unrestricted进行权限更改，输入Y确认

![img](https://img.arctee.cn/one/202209171717881.png)



3、打开“任务计划程序”，方法是依次单击“控制面板”、“系统和安全性”、“管理工具”，然后双击“任务计划程序”。‌  需要管理员权限 如果系统提示您输入管理员密码或进行确认，请键入该密码或提供确认。
单击“操作”菜单，然后单击“创建任务”。
配置如下：

常规：键入任务的名称比如SetWallPaperFromSpotlight和描述（可选）  - 勾选“使用最高权限运行”

![img](https://img.arctee.cn/one/202209171717311.png)



触发器：新建 - 选择“制定计划时” - 选择 执行时间如“7:30:00” - 选择执行周期如“每天 每隔1天发生一次” - 勾选"启用"，也可以根据需要选择每小时，每半小时或者更高的频率运行脚本。

![img](https://img.arctee.cn/one/202209171718579.png)



操作：新建 - 选择“启动程序” - "powershell" ，添加参数为文件路径，如"D:\code\py\SetWallPaperFromSpotlight.ps1"，- 点击“确定”
![img](https://img.arctee.cn/one/202209171718980.png)

所有完成就大功告成了，要检查效果的话，单机左侧的任务计划程序库，从右边找到你刚设置的SetWallPaperFromSpotlight任务，右键立即运行就可以看到效果了。

PS：
首先，确保你的 Windows 10 已经开启了“聚焦”壁纸功能，桌面右键 > 个性化 > 锁屏界面 > “背景”选项下选择 “Windows 聚焦”即为开启，之后系统将会自动联网更换锁屏壁纸。为了使任务栏颜色随着壁纸改变，最好将颜色设置为从壁纸中自动选取。



> 转载自：https://blog.csdn.net/anymake_ren/article/details/51125609

