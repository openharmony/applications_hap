# 系统应用<a name="ZH-CN_TOPIC_0000001162045697"></a>

-   [简介](#section110mcpsimp)
-   [目录](#section11948105210591)
-   [相关仓](#section120mcpsimp)

## 简介<a name="section110mcpsimp"></a>

系统应用提供了OpenHarmony标准系统上的部分应用，如桌面、SystemUI、设置等，为开发者提供了构建标准系统应用的具体实例，这些应用支持在所有标准系统的设备上使用。

系统应用目前包含如下：

1.  桌面：提供了基本的已安装应用的展示功能和人机交互界面，是所有应用的入口。
2.  SystemUI：包含导航栏和系统状态栏两部分，导航栏提供基本页面导航功能，状态栏提供系统状态显示，如时间、充电状态等。
3.  设置：提供了关于设备，应用管理，亮度设置等功能。

除以上系统应用之外，还预置了一些简单的示例应用，如时钟、计算器、空气质量等，可供开发者参考学习。

由于各个应用使用的SDK版本可能并不相同，本仓以预购建HAP包的形式归档这些应用。

[pipeline.md](pipline.md)记录了通过[OpenHarmony流水线](http://ci.openharmony.cn/dailys/dailybuilds)构建出这些应用的永久归档地址。各个应用的源码和SDK版本信息和可以在对应流水线提供的元数据中查询，构建方法可以参考流水线归档产物中记录的构建命令或应用源码仓的README。

## 目录<a name="section11948105210591"></a>

```
applications/standard/hap
├── resources                      # 预制资源目录
├── Airquality_Demo.hap            # 空气质量示例应用
├── Calc_Demo.hap                  # 计算器示例应用
├── Clock_Demo.hap                 # 简单时钟示例应用
├── Ecg_Demo.hap                   # 心电图显示示例应用
├── Flashlight_Demo.hap            # 手电筒示例应用
├── Photos.hap                     # 图库应用
├── Launcher.hap                   # 桌面entry应用
├── Launcher_Recents.hap           # 桌面中最近任务应用
├── Launcher_Settings.hap          # 桌面中的桌面设置应用
├── Settings.hap                   # 设置应用
├── Settings_FaceAuth.hap          # 人脸认证设置应用
├── SystemUI-NavigationBar.hap     # SystemUI 导航栏应用
├── SystemUI-StatusBar.hap         # SystemUI 状态栏应用
├── SystemUI-ScreenLock.hap        # SystemUI 锁屏应用
├── SystemUI-SystemDialog.hap      # SystemUI 系统弹框应用
├── Music_Demo.hap                 # 音乐示例应用
├── Camera.hap                     # 相机应用
├── CallUI.hap                     # 通话应用
├── PermissionManager.hap          # 权限管理应用
```

## 相关仓<a name="section120mcpsimp"></a>

系统应用

[applications\_standard\_settings](https://gitee.com/openharmony/applications_settings)

[applications\_standard\_launcher](https://gitee.com/openharmony/applications_launcher)

[applications\_standard\_systemui](https://gitee.com/openharmony/applications_systemui)

**applications\_standard\_hap**

**[device_manager](https://gitee.com/openharmony/device_manager)**
