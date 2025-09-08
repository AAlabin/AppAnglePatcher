//
//  AppDelegate.swift
//  AppAnglePatcher
//
//  Created by Alexey Alabin on 07.09.2025.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow!
    var mainViewController: ViewController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Просто устанавливаем заголовок для главного окна
        if let mainWindow = NSApp.windows.first {
            mainWindow.title = "App Angle Patcher"
        }
    }
    
    private func createMainWindow() {
        let windowSize = NSSize(width: 800, height: 600)
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        let windowRect = NSRect(
            x: (screenFrame.width - windowSize.width) / 2,
            y: (screenFrame.height - windowSize.height) / 2,
            width: windowSize.width,
            height: windowSize.height
        )
        
        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = "App Angle Patcher"
        window.subtitle = "Patch apps to launch with --use-angle=gl"
        window.minSize = NSSize(width: 700, height: 500)
        window.backgroundColor = NSColor.windowBackgroundColor
        
        // Центрируем окно
        window.center()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // Убираем создание дополнительных окон
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            window.makeKeyAndOrderFront(nil)
        }
        return true
    }
}
