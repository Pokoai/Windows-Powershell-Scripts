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


Remove-Item "$($env:USERPROFILE)\Pictures\Spotlight\CopyAssets\*";