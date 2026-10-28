# 机械革命蛟龙 16S OpenCore EFI

适用于机械革命蛟龙 16S（GM6XG0X），AMD Ryzen 9 7940HS + NVIDIA GeForce RTX 4060 Laptop GPU。

这份 EFI 已由机主在 macOS 26 实机上长期测试，作为本机日用配置。下表记录已完成的功能测试。

## 硬件与配置

| 项目 | 型号 / 配置 |
| --- | --- |
| 机型 | MECHREVO JIAOLONG16S SERIES GM6XG0X |
| CPU | AMD Ryzen 9 7940HS，8 核 16 线程 |
| 独立显卡 | NVIDIA GeForce RTX 4060 Laptop GPU |
| 集成显卡 | AMD Radeon 780M |
| 无线网卡 | Intel Wi-Fi 6 AX200 160MHz |
| 蓝牙 | Intel Wireless Bluetooth |
| 板载声卡 | Realtek ALC256 |
| 有线网卡 | Realtek PCIe GbE Family Controller，PCI ID `10EC:8168` |
| SMBIOS | `MacBookPro16,2` |

## 功能测试

测试状态由机主的 macOS 实机验证确认。

| 功能 | 状态 | 说明 |
| --- | --- | --- |
| 图形启动菜单 | 已配置 | OpenCanopy + GoldenGate 主题 |
| NVIDIA 独显 | 显示正常 | 使用 NullMoth NVIDIA Driver，显卡可识别，图形加速与系统动画正常；命令行查询未报告 Metal 支持 |
| Wi-Fi | 正常 | 使用 `AirportItlwm.kext`，系统原生 Wi-Fi 菜单可用 |
| 定位 | 正常 | 已实测定位功能 |
| 蓝牙 | 正常 | 已测试连接 AirPods |
| USB | 正常 | 已定制端口映射，使用 `XhciNudge.kext` 解决原有明显延迟 |
| 内置键盘 | 正常 | 已实测 |
| 触控板 | 正常 | 已实测 |
| 屏幕亮度调节 | 正常 | 笔记本内屏亮度可调 |
| 内置扬声器 | 正常 | 音频输出正常 |
| 内置麦克风 | 正常 | 音频输入正常 |
| 睡眠 | 正常 | 已实测 |
| 有线耳机 | 未测试 | 待验证 |
| 有线网口 | 未测试 | 已配置 `RealtekRTL8111.kext`，暂未接网线测试 |
| 摄像头 | 未测试 | 待验证 |

## 关键驱动与修复

### 图形启动菜单

使用 `OpenCore-1.0.8-RELEASE` 包中的 `OpenCanopy.efi`，搭配现有 GoldenGate 主题资源：

- `Misc → Boot → PickerMode`：`External`。
- `Misc → Boot → PickerVariant`：`Acidanthera\GoldenGate`。
- 背景使用纯黑色（`DefaultBackgroundColor = 00000000`），已移除 `Background.icns` 背景图片。
- `PickerAttributes` 保持 `17`，倒计时保持 `5` 秒。
- `UEFI → Output → Resolution` 保持 `Max`。

主题图标、字体和标签位于 `OC/Resources`。更新 OpenCore 时，应同时使用对应版本的 OpenCanopy。参考 [OpenCore 图形菜单教程](https://sumingyd.github.io/OpenCore-Post-Install/cosmetic/gui.html)。

OpenCore 日志已关闭：`Misc → Debug` 中 `Target=0`、`AppleDebug=false`、`ApplePanic=false`、`SysReport=false`。

### NVIDIA 显卡

使用 [NullMoth NVIDIA Driver](https://github.com/nullmoth/nvidia-macos-driver)。驱动需按项目说明在 macOS 中单独安装，EFI 中的相关配置与其配套使用。

### USB 映射与延迟

- `USBToolBox.kext` 与本机定制的 `UTBMap.kext` 配套使用。
- `XhciPortLimit` 保持 `False`。
- 本机曾在 macOS 中出现明显的 USB 延迟，加入 [XhciNudge.kext](https://github.com/MonkaKokosowa/XhciNudge) 后，经实测已解决。

### 板载音频

- Realtek ALC256 使用 `AppleALC.kext` 与 `SimpleHDA.kext`。
- 当前启动参数为 `alcid=11`。
- 已验证内置扬声器和麦克风；有线耳机待测试。

### 键盘与触控板

- 内置键盘使用 `VoodooPS2Controller.kext` 及键盘插件。
- 触控板使用 `VoodooI2C.kext` 与 `VoodooI2CHID.kext`。
- 当前保留 `-vi2c-force-polling` 启动参数。

### ALIB 电源状态修复

`config.plist` 中包含针对本机固件 `AmdTable` 的 ACPI 补丁：

```text
ALIB AC/DC: avoid reading a return value from void A026
```

固件中的 `ALIB` 曾读取无返回值的 `A026()`，导致电源适配器 `_PSR` 查询反复触发 `AE_AML_NO_RETURN_VALUE`。补丁保留原有电源状态切换操作，修正返回值处理。

## macOS 26 首次设置黑屏

机主安装 macOS 26 后，首次启动曾黑屏，无法完成设置助理（激活向导）；据机主排查，设置助理的背景动态壁纸崩溃。机主通过在 Recovery 中运行 [recovery-skip.sh](recovery-skip.sh) 跳过首次设置，之后成功进入系统。

### 跳过激活向导脚本

运行脚本，按编号选择数据卷，输入用户名和显示名称，核对目标后创建本地管理员并跳过首次设置。

- 必须先启动安装好的 macOS 一次，在首次设置黑屏、卡住后，再进入 Recovery 执行脚本。
- 目标数据卷需在 Recovery 中挂载并解锁，脚本会列出已生成本地账户数据库的数据卷。
- 目标尚未完成首次设置；新建用户名、对应主目录和 UID `501` 均未被占用。

脚本使用 UID `501` 创建管理员，主目录为 `/Users/所选用户名`。脚本会修改目标系统的本地账户数据库，执行前会显示目标摘要，输入 `YES` 后才开始写入。

### 运行步骤

1. 将 `recovery-skip.sh` 放到可在 Recovery 中访问的 U 盘根目录。
2. 安装完成后，先启动安装好的 macOS，让系统进入首次设置并复现黑屏、卡住的情况，再重启进入 Recovery。
3. 在 Recovery 的磁盘工具中挂载、解锁目标数据卷，然后打开「实用工具 → 终端」。
4. 用 `ls /Volumes` 确认 U 盘卷名，然后运行以下命令，将示例中的 `你的U盘卷名` 替换为实际名称：

   ```sh
   sh "/Volumes/你的U盘卷名/recovery-skip.sh"
   ```

5. 按编号选择目标数据卷，输入用户名和显示名称。用户名以小写字母开头，只使用小写字母、数字、下划线和连字符；显示名称留空时使用用户名。
6. 核对数据卷和账户摘要，输入 `YES` 继续；其他输入会取消且不写入。
7. 按提示为新账户设置自己的非空登录密码，输入时不显示字符。
8. 看到 `DONE` 后重启，选择安装好的 macOS，并使用刚创建的账户登录。

若提示找不到已初始化的数据卷，先确认已按第 2 步启动过安装好的 macOS，再检查数据卷是否已挂载、解锁。

脚本会备份原管理员组记录，创建账户和主目录，最后写入 `.AppleSetupDone`。若写入过程中出现 `STOP`，按上方具体错误检查当前账户状态；脚本不会自动回滚已完成的步骤。

## 使用

本目录结构：

```text
BOOT/
OC/
  ACPI/
  Drivers/
  Kexts/
  Resources/
  OpenCore.efi
  config.plist
README.md
recovery-skip.sh
```

1. 备份现有 EFI，保留可启动的恢复副本。
2. 将本目录中的 `BOOT`、`OC` 放入启动盘的 `EFI` 目录，最终路径应为 `EFI/BOOT`、`EFI/OC`。
3. 按 NullMoth 项目说明在 macOS 中安装 NVIDIA 驱动。
4. 使用本机配置测试启动；其他机器或更换硬件后，需要重新核对 ACPI、USB 映射和设备配置。

## 相关项目

- [OpCore Simplify](https://github.com/lzhoang2801/OpCore-Simplify)
- [OpenCorePkg](https://github.com/acidanthera/OpenCorePkg)
- [NullMoth NVIDIA Driver](https://github.com/nullmoth/nvidia-macos-driver)
- [AirportItlwm / itlwm](https://github.com/laobamac/itlwm)
- [USBToolBox](https://github.com/USBToolBox/tool)
- [XhciNudge](https://github.com/MonkaKokosowa/XhciNudge)
- [AppleALC](https://github.com/acidanthera/AppleALC)
- [SimpleHDA](https://github.com/laobamac/SimpleHDA)
- [VoodooI2C](https://github.com/VoodooI2C/VoodooI2C)
- [VoodooPS2](https://github.com/acidanthera/VoodooPS2)
