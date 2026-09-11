//@ pragma UseQApplication
//@ pragma QmlImportPath: "."
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import "./Layers" as Lay
import "./Widgets" as Wid

ShellRoot {
    Variants {
        model: Quickshell.screens
        Scope {
            id: scopeRoot
            required property ShellScreen modelData
            Wid.WallpaperEngine {
                modelData: scopeRoot.modelData
            }
        }
    }
    Lay.Capsule {}
    Lay.Clock {}
    Lay.Workspaces {}
    Lay.AppDrawer {}
    Lay.VolumeOsd {}
    Lay.BrightnessOsd {}
    Lay.BrightnessCorner {}
    Lay.Notifications {}
    Lay.Searchapp {}
    Lay.Tray {}
}
