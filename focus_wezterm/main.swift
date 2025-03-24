import Cocoa
import ApplicationServices
import Foundation

let TARGET_APP = "com.github.wez.wezterm"

func launchApp() {
    let process = Process()
    process.launchPath = "/usr/bin/open"
    process.arguments = ["-b", TARGET_APP]

    do {
        try process.run()
        process.waitUntilExit()
    } catch {
    }
}

func activateApp(app: NSRunningApplication) {
    app.activate()
}

func openNewWindow(app: NSRunningApplication) {
    // This case is impossible. But just in case, activate the app
    app.activate()
}

func processApp() -> Int {
    let runningApps = NSWorkspace.shared.runningApplications

    for app in runningApps {
        if app.isTerminated {
            continue
        }
        if app.bundleIdentifier != TARGET_APP {
            continue
        }
        if let screen = NSScreen.main {
            let screenWidth = screen.frame.width
            let screenHeight = screen.frame.height
        
            let options: CGWindowListOption = [.excludeDesktopElements, .optionAll]
            if let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
                var count = 0
                for window in windows {
                    if let ownerPID = window[kCGWindowOwnerPID as String] as? Int {
                        if ownerPID == app.processIdentifier {
                            if let boundsDictionary = window[kCGWindowBounds as String] as? [String: CGFloat],
                               let x = boundsDictionary["X"],
                               let y = boundsDictionary["Y"],
                               let width = boundsDictionary["Width"],
                               let height = boundsDictionary["Height"] {
                                if width <= 100 || height <= 100 {
                                    continue
                                }
                                if x == 0 && width == 500 && y + 500 == screenHeight {
                                    continue
                                }
                                if x == 0 && y == 0 && width == screenWidth && height == 24 {
                                    continue
                                }
                            }
                            count = count + 1
                            if count > 0 {
                                break // short-cut
                            }
                        }
                    }
                }
                if count > 0 {
                    activateApp(app:app)
                } else {
                    openNewWindow(app:app)
                }
                return count
            }
        }
    }
    launchApp()
    return -1
}

let count = processApp()
switch count {
case -1:
    print("App not running. Launch")
    break
case 0:
    print("No window found. Open new window")
    break
default:
    print("Window found. Activate")
    break
}

