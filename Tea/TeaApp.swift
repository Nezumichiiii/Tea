//
//  TeaApp.swift
//  Tea
//

import AppKit
import ServiceManagement
import SwiftUI

@main
struct TeaApp: App {
    @NSApplicationDelegateAdaptor(TeaStatusBarController.self)
    private var statusBarController

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class TeaStatusBarController: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: 26)
    private var sleepPreventionActivity: NSObjectProtocol?
    private var iconAnimationTimer: Timer?
    private var animationFrame = 0
    private var isKeepingAwake = false

    private var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    override init() {
        super.init()
        configureStatusItem()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        updateStatusItem()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.image = makeStatusImage()
        button.toolTip = "Tea — click to keep your Mac awake"
        button.setAccessibilityLabel("Tea, mode off")
    }

    @objc private func handleStatusItemClick(_ sender: Any?) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else {
            toggleKeepAwake()
        }
    }

    private func toggleKeepAwake() {
        isKeepingAwake.toggle()

        if isKeepingAwake {
            sleepPreventionActivity = ProcessInfo.processInfo.beginActivity(
                options: [.idleSystemSleepDisabled, .idleDisplaySleepDisabled],
                reason: "Tea keeps the Mac awake"
            )
        } else if let sleepPreventionActivity {
            ProcessInfo.processInfo.endActivity(sleepPreventionActivity)
            self.sleepPreventionActivity = nil
        }

        startIconTransition()
    }

    private func startIconTransition() {
        iconAnimationTimer?.invalidate()
        animationFrame = 0
        updateStatusItem()

        guard isKeepingAwake else {
            return
        }

        iconAnimationTimer = Timer.scheduledTimer(
            timeInterval: 0.07,
            target: self,
            selector: #selector(advanceIconTransition),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func advanceIconTransition() {
        animationFrame += 1
        updateStatusItem()

        if animationFrame >= 5 {
            iconAnimationTimer?.invalidate()
            iconAnimationTimer = nil
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = isLaunchAtLoginEnabled ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Tea",
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        guard let button = statusItem.button else {
            return
        }

        menu.popUp(
            positioning: nil,
            at: NSPoint(x: button.bounds.midX, y: button.bounds.minY),
            in: button
        )
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if isLaunchAtLoginEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Tea login item error: %@", error.localizedDescription)
        }
    }

    @objc private func quitApplication() {
        NSApp.terminate(nil)
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.image = makeStatusImage()
        button.contentTintColor = nil
        button.toolTip = isKeepingAwake
            ? "Tea — keeping your Mac awake"
            : "Tea — click to keep your Mac awake"
        button.setAccessibilityLabel(
            isKeepingAwake ? "Tea, mode on" : "Tea, mode off"
        )
    }

    private func makeStatusImage() -> NSImage {
        let canvas = NSImage(size: NSSize(width: 24, height: 24))
        let cup = NSImage(
            systemSymbolName: isKeepingAwake ? "cup.and.saucer.fill" : "cup.and.saucer",
            accessibilityDescription: "Tea"
        ) ?? NSImage(
            systemSymbolName: "cup.and.saucer",
            accessibilityDescription: "Tea"
        )
        let smoke = NSImage(
            systemSymbolName: "smoke",
            accessibilityDescription: "Tea is on"
        )

        canvas.lockFocus()

        cup?.draw(
            in: NSRect(x: 2, y: 0, width: 20, height: 20),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )

        if isKeepingAwake {
            let smokeOffset = min(CGFloat(animationFrame) * 0.7, 2.8)
            smoke?.draw(
                in: NSRect(x: 8, y: 9 + smokeOffset, width: 8, height: 10),
                from: .zero,
                operation: .sourceOver,
                fraction: 1
            )
        }

        canvas.unlockFocus()
        canvas.isTemplate = true
        return canvas
    }

    func applicationWillTerminate(_ notification: Notification) {
        iconAnimationTimer?.invalidate()

        if let sleepPreventionActivity {
            ProcessInfo.processInfo.endActivity(sleepPreventionActivity)
        }
    }
}
