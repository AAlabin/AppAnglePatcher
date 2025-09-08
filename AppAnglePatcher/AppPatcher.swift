//
//  AppPatcher.swift
//  AppAnglePatcher
//
//  Created by Alexey Alabin on 07.09.2025.
//

import Foundation

class AppPatcher {
    
    private let fileManager = FileManager.default
    
    // Target applications to look for
    private let targetAppNames = [
        "Яндекс", "Yandex", "Яндекс браузер", "Yandex Browser",
        "Яндекс музыка", "Yandex Music",
        "Xcode", "Simulator", "Instruments",
        "Google Chrome", "Chromium", "Microsoft Edge",
        "Brave Browser", "Discord", "Slack",
        "Visual Studio Code", "Electron", "WhatsApp"
    ]
    
    func findAllApplications() -> [AppInfo] {
        var apps: [AppInfo] = []
        
        let searchPaths = [
            "/Applications",
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        ]
        
        for searchPath in searchPaths {
            if let enumerator = fileManager.enumerator(at: URL(fileURLWithPath: searchPath),
                                                     includingPropertiesForKeys: [.isDirectoryKey],
                                                     options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension == "app" {
                        if let appInfo = getAppInfo(from: fileURL, includeAll: true) {
                            apps.append(appInfo)
                        }
                    }
                }
            }
        }
        
        return apps
    }
    
    func findTargetApplications() -> [AppInfo] {
        return findAllApplications().filter { $0.isTargetApp }
    }
    
    private func getAppInfo(from appURL: URL, includeAll: Bool = false) -> AppInfo? {
        let appName = appURL.deletingPathExtension().lastPathComponent
        let infoPlistURL = appURL.appendingPathComponent("Contents").appendingPathComponent("Info.plist")
        var bundleIdentifier: String?
        var isPatched = false
        var isTargetApp = false
        
        if let plistData = try? Data(contentsOf: infoPlistURL),
           let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
            bundleIdentifier = plist["CFBundleIdentifier"] as? String
            if let executableName = plist["CFBundleExecutable"] as? String {
                let macosURL = appURL.appendingPathComponent("Contents").appendingPathComponent("MacOS")
                let originalBackup = macosURL.appendingPathComponent("\(executableName).original")
                isPatched = fileManager.fileExists(atPath: originalBackup.path)
            }
            isTargetApp = targetAppNames.contains { target in
                appName.localizedCaseInsensitiveContains(target)
            }
            if !isTargetApp {
                isTargetApp = isXcodeRelated(appName: appName, appURL: appURL, plist: plist)
            }
            if !isTargetApp {
                isTargetApp = isChromiumRelated(bundleIdentifier: bundleIdentifier, plist: plist)
            }
        }
        if !includeAll && !isTargetApp {
            return nil
        }
        
        return AppInfo(
            name: appName,
            path: appURL.path,
            bundleIdentifier: bundleIdentifier,
            isPatched: isPatched,
            isTargetApp: isTargetApp
        )
    }
    
    private func isXcodeRelated(appName: String, appURL: URL, plist: [String: Any]) -> Bool {
        let xcodeIndicators = ["xcode", "simulator", "instruments"]
        let appNameLower = appName.lowercased()
        let pathLower = appURL.path.lowercased()
        for indicator in xcodeIndicators {
            if appNameLower.contains(indicator) {
                return true
            }
        }
        if pathLower.contains("/xcode.app/contents/applications/") {
            return true
        }
        if let bundleId = plist["CFBundleIdentifier"] as? String,
           bundleId.contains("com.apple.dt") || bundleId.lowercased().contains("xcode") {
            return true
        }
        return false
    }
    
    private func isChromiumRelated(bundleIdentifier: String?, plist: [String: Any]) -> Bool {
        guard let bundleId = bundleIdentifier?.lowercased() else { return false }
        if bundleId.contains("chromium") || bundleId.contains("chrome") || bundleId.contains("electron") {
            return true
        }
        if let executable = plist["CFBundleExecutable"] as? String,
           executable.lowercased().contains("chromium") || executable.lowercased().contains("chrome") {
            return true
        }
        return false
    }
    
    func patchApp(app: AppInfo, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let appURL = URL(fileURLWithPath: app.path)
            
            // Создаем копию приложения в папке Загрузки
            let downloadsDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
            let patchedAppURL = downloadsDir.appendingPathComponent("\(app.name).app")
            
            do {
                // Удаляем старую копию если существует
                if self.fileManager.fileExists(atPath: patchedAppURL.path) {
                    try self.fileManager.removeItem(at: patchedAppURL)
                }
                
                // Копируем приложение в Загрузки
                try self.fileManager.copyItem(at: appURL, to: patchedAppURL)
                print("Copied \(app.name) to Downloads for patching: \(patchedAppURL.path)")
                
            } catch {
                print("Error copying app to Downloads: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // Создаем AppInfo для пропатченной копии
            let patchedAppInfo = AppInfo(
                name: "\(app.name) (Patched)",
                path: patchedAppURL.path,
                bundleIdentifier: app.bundleIdentifier,
                isPatched: false,
                isTargetApp: app.isTargetApp
            )
            
            // Патчим копию в Загрузках
            let success = self.patchAppDirectly(app: patchedAppInfo)
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    private func hasFullDiskAccess() -> Bool {
        let testPath = "/Applications"
        return fileManager.isWritableFile(atPath: testPath)
    }
    
    private func patchAppDirectly(app: AppInfo) -> Bool {
        let appURL = URL(fileURLWithPath: app.path)
        
        let infoPlistURL = appURL.appendingPathComponent("Contents").appendingPathComponent("Info.plist")
        guard let plistData = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
              let executableName = plist["CFBundleExecutable"] as? String else {
            return false
        }
        
        let macosURL = appURL.appendingPathComponent("Contents").appendingPathComponent("MacOS")
        let originalExecutable = macosURL.appendingPathComponent(executableName)
        let backupExecutable = macosURL.appendingPathComponent("\(executableName).original")
        
        // Check if already patched
        if fileManager.fileExists(atPath: backupExecutable.path) {
            print("App \(app.name) is already patched")
            return true
        }
        
        // Create backup of original executable
        do {
            try fileManager.copyItem(at: originalExecutable, to: backupExecutable)
        } catch {
            print("Error creating executable backup: \(error)")
            return false
        }
        
        // Create wrapper script
        let wrapperScript = """
        #!/bin/bash
        ORIGINAL_EXECUTABLE="$(dirname "$0")/\(executableName).original"
        APP_NAME="\(app.name)"
        echo "Launching $APP_NAME with OpenGL (--use-angle=gl)"
        exec "$ORIGINAL_EXECUTABLE" --use-angle=gl "$@"
        """
        
        do {
            try wrapperScript.write(to: originalExecutable, atomically: true, encoding: .utf8)
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: originalExecutable.path)
            print("Successfully patched \(app.name) at \(appURL.path)")
            return true
        } catch {
            print("Error creating wrapper: \(error)")
            // Restore original executable if wrapper creation fails
            try? fileManager.removeItem(at: originalExecutable)
            try? fileManager.moveItem(at: backupExecutable, to: originalExecutable)
            return false
        }
    }
    
    func restoreApp(app: AppInfo, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let appURL = URL(fileURLWithPath: app.path)
            
            // Check write access
            if !self.fileManager.isWritableFile(atPath: appURL.path) {
                print("No write access to \(app.name)")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let infoPlistURL = appURL.appendingPathComponent("Contents").appendingPathComponent("Info.plist")
            guard let plistData = try? Data(contentsOf: infoPlistURL),
                  let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
                  let executableName = plist["CFBundleExecutable"] as? String else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let macosURL = appURL.appendingPathComponent("Contents").appendingPathComponent("MacOS")
            let originalExecutable = macosURL.appendingPathComponent(executableName)
            let backupExecutable = macosURL.appendingPathComponent("\(executableName).original")
            
            // Check if backup exists
            guard self.fileManager.fileExists(atPath: backupExecutable.path) else {
                print("No backup found for \(app.name)")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            do {
                // Remove wrapper script
                if self.fileManager.fileExists(atPath: originalExecutable.path) {
                    try self.fileManager.removeItem(at: originalExecutable)
                }
                
                // Restore original executable
                try self.fileManager.moveItem(at: backupExecutable, to: originalExecutable)
                
                print("Successfully restored \(app.name)")
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("Error restoring app: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    func createPatchScript(for app: AppInfo) -> String {
        let appURL = URL(fileURLWithPath: app.path)
        
        let infoPlistURL = appURL.appendingPathComponent("Contents").appendingPathComponent("Info.plist")
        guard let plistData = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
              let executableName = plist["CFBundleExecutable"] as? String else {
            return ""
        }
        
        let macosPath = appURL.appendingPathComponent("Contents").appendingPathComponent("MacOS").path
        let originalExecutablePath = macosPath + "/" + executableName
        let backupExecutablePath = macosPath + "/" + executableName + ".original"
        
        return """
        #!/bin/bash
        
        # Patch script for \(app.name)
        echo "Patching \(app.name)..."
        
        # Check if original exists
        if [ ! -f "\(originalExecutablePath)" ]; then
            echo "Error: Original executable not found at \(originalExecutablePath)"
            exit 1
        fi
        
        # Check if already patched
        if [ -f "\(backupExecutablePath)" ]; then
            echo "App is already patched"
            exit 0
        fi
        
        # Backup original
        echo "Creating backup of executable..."
        sudo cp "\(originalExecutablePath)" "\(backupExecutablePath)"
        
        # Create wrapper script
        echo "Creating wrapper..."
        sudo cat > "\(originalExecutablePath)" << 'EOF'
        #!/bin/bash
        ORIGINAL_EXEC="$(dirname "$0")/\(executableName).original"
        echo "Launching \(app.name) with OpenGL (--use-angle=gl)"
        exec "$ORIGINAL_EXEC" --use-angle=gl "$@"
        EOF
        
        # Make executable
        echo "Setting permissions..."
        sudo chmod +x "\(originalExecutablePath)"
        
        echo "Successfully patched \(app.name)"
        echo "Original executable backed up to: \(backupExecutablePath)"
        """
    }

    func executePatchScript(for app: AppInfo) -> Bool {
        let script = createPatchScript(for: app)
        let safeAppName = app.name.replacingOccurrences(of: " ", with: "_")
        let scriptURL = FileManager.default.temporaryDirectory.appendingPathComponent("patch_\(safeAppName).sh")
        
        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
            
            let appleScript = """
            do shell script "bash '\(scriptURL.path)'" with administrator privileges
            """
            
            print("Executing script: \(scriptURL.path)")
            return executeAppleScript(appleScript)
        } catch {
            print("Error creating script: \(error)")
            return false
        }
    }
    
    func patchAppWithTerminal(app: AppInfo) -> Bool {
        let appURL = URL(fileURLWithPath: app.path)
        
        // Get executable info from Info.plist
        let infoPlistURL = appURL.appendingPathComponent("Contents").appendingPathComponent("Info.plist")
        guard let plistData = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
              let executableName = plist["CFBundleExecutable"] as? String else {
            return false
        }
        
        let macosPath = appURL.appendingPathComponent("Contents").appendingPathComponent("MacOS").path
        let originalExecutablePath = macosPath + "/" + executableName
        let backupExecutablePath = macosPath + "/" + executableName + ".original"
        
        let appleScript = """
        do shell script "\
        # Check if already patched
        if [ -f '\(backupExecutablePath)' ]; then
            echo 'App is already patched'
            exit 0
        fi && \
        
        # Backup original executable
        sudo cp '\(originalExecutablePath)' '\(backupExecutablePath)' && \
        
        # Create wrapper script
        echo '#!/bin/bash
        ORIGINAL_EXEC=\\\"$(dirname \\\"\\\\$0\\\")/\(executableName).original\\\"
        echo \\\"Launching \(app.name) with OpenGL (--use-angle=gl)\\\"
        exec \\\"\\\\$ORIGINAL_EXEC\\\" --use-angle=gl \\\"\\\\$@\\\"' | sudo tee '\(originalExecutablePath)' > /dev/null && \
        
        # Make script executable
        sudo chmod +x '\(originalExecutablePath)'" \
        with administrator privileges
        """
        
        print("Executing AppleScript: \(appleScript)")
        return executeAppleScript(appleScript)
    }
    
    private func executeAppleScript(_ script: String) -> Bool {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            _ = scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript error: \(error)")
                return false
            }
            print("AppleScript executed successfully")
            return true
        }
        return false
    }
}
