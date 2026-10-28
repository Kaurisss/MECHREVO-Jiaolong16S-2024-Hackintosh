# 机械革命蛟龙 16S OpenCore EFI

适用于机械革命蛟龙 16S（GM6XG0X），AMD Ryzen 9 7940HS + NVIDIA GeForce RTX 4060 Laptop GPU。

这份 EFI 已由机主在 macOS 实机上长期测试，作为本机日用配置。下表记录已完成的功能测试；macOS 具体测试版本待补充。

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
| NVIDIA 独显 | 正常 | 使用 NullMoth NVIDIA Driver，可识别显卡并显示 Metal 支持 |
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

## SMBIOS 身份信息

公开版已清理设备身份信息。使用前，请在准备部署到启动盘的副本中填写自己的值：

| `PlatformInfo → Generic` 字段 | 公开版占位值 | 使用前填写 |
| --- | --- | --- |
| `SystemSerialNumber` | 空字符串 | 自行生成的序列号 |
| `MLB` | 空字符串 | 与序列号配套生成的主板序列号 |
| `SystemUUID` | 空字符串 | 自行生成的 UUID |
| `ROM` | 六个零字节 | 自己网卡的 MAC 地址，去掉分隔符后按六字节 Data 填写 |

`SystemProductName` 保持 `MacBookPro16,2`。可使用 [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) 生成对应机型的身份信息，具体步骤参考 [Dortania iServices 指南](https://dortania.github.io/OpenCore-Post-Install/universal/iservices.html)。

## 使用

本目录结构：

```text
BOOT/
OC/
  ACPI/
  Drivers/
  Kexts/
  OpenCore.efi
  config.plist
README.md
```

1. 备份现有 EFI，保留可启动的恢复副本。
2. 在准备部署的副本中填写上述 SMBIOS 身份信息。
3. 将副本中的 `BOOT`、`OC` 放入启动盘的 `EFI` 目录，最终路径应为 `EFI/BOOT`、`EFI/OC`。
4. 按 NullMoth 项目说明在 macOS 中安装 NVIDIA 驱动。
5. 使用本机配置测试启动；其他机器或更换硬件后，需要重新核对 ACPI、USB 映射和设备配置。

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
