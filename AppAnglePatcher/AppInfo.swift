//
//  AppInfo.swift
//  AppAnglePatcher
//
//  Created by Alexey Alabin on 07.09.2025.
//

import Foundation

struct AppInfo: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let bundleIdentifier: String?
    let isPatched: Bool
    let isTargetApp: Bool
    
    init(name: String, path: String, bundleIdentifier: String? = nil, isPatched: Bool = false, isTargetApp: Bool = true) {
        self.name = name
        self.path = path
        self.bundleIdentifier = bundleIdentifier
        self.isPatched = isPatched
        self.isTargetApp = isTargetApp
    }
}
