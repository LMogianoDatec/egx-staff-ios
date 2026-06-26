//
//  EGXStaffApp.swift
//  EGX Staff
//
//  Created by Leonardo Mogiano on 25/06/2026.
//

import SwiftUI

@main
struct EGXStaffApp: App {
    init() {
        Injection.setup()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
