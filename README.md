# System Apps \(HAP\)<a name="EN-US_TOPIC_0000001162045697"></a>

-   [Introduction](#section110mcpsimp)
-   [Directory Structure](#section11948105210591)
-   [Repositories Involved](#section120mcpsimp)

## Introduction<a name="section110mcpsimp"></a>

This module provides some system apps that are applicable to the OpenHarmony standard system, such as Launcher, SystemUI, and Settings. It also provides specific examples for you to build standard-system apps, which can be installed on all devices running the standard system.

Currently, OpenHarmony supports the following system apps:

1.  Launcher: acts as a main entry for all apps and provides UIs for display and human-machine interactions of installed apps.
2.  SystemUI: consists of the navigation bar and system status bar. The navigation bar provides page navigation, and the status bar displays the system status, such as the time and charging status.
3.  Settings: provides functions such as device management, app management, and brightness setting.

In addition to these system apps, OpenHarmony provides some simple sample apps for your reference, such as the clock, calculator, and air quality app.

Since SDK versions may be different for each application, these applications are preset in the form of pre-built HAP archives.

[pipeline.md](pipline.md) records the permanent archive addresses for these applications built through the [OpenHarmony pipeline](http://ci.openharmony.cn/dailys/dailybuilds). The source code and SDK version information for each application can be queried in the metadata provided by the corresponding pipeline, and the build guides can be refered to the commands recorded in the pipeline archives or the README of the application source repositories.

## Directory Structure<a name="section11948105210591"></a>

```
applications/standard/hap
├── resources                      # Preset resources directory
├── Airquality_Demo.hap            # Sample air quality app
├── Calc_Demo.hap                  # Sample calculator app
├── Clock_Demo.hap                 # Sample clock app
├── Ecg_Demo.hap                   # Sample electrocardiogram (ECG) app
├── Flashlight_Demo.hap            # Sample flashlight app
├── Photos.hap                     # Photos app
├── Launcher.hap                   # Launcher app
├── Launcher_Recents.hap           # Recent tasks app of Launcher
├── Launcher_Settings.hap          # Settings app of Launcher
├── Settings.hap                   # Settings app
├── Settings_FaceAuth.hap          # Settings app of FaceAuth
├── SystemUI-NavigationBar.hap     # Navigation bar app of SystemUI
├── SystemUI-StatusBar.hap         # Status bar app of SystemUI
├── SystemUI-ScreenLock.hap        # ScreenLock app of SystemUI
├── SystemUI-SystemDialog.hap      # System dialog app of SystemUI
├── Music_Demo.hap                 # Sample music app
├── Camera.hap                     # Camera app
├── Media_Library.hap              # Media library data ability app
├── Media_Scanner.hap              # Media scanner app
├── CallUI.hap                     # Call ui app
├── PermissionManager.hap          # Permission manager app
```

## Repositories Involved<a name="section120mcpsimp"></a>

System apps

[applications\_standard\_settings](https://gitee.com/openharmony/applications_settings)

[applications\_standard\_launcher](https://gitee.com/openharmony/applications_launcher)

[applications\_standard\_systemui](https://gitee.com/openharmony/applications_systemui)

**applications\_standard\_hap**

**[device_manager](https://gitee.com/openharmony/device_manager)**
