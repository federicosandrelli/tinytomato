import AppKit

enum Phase {
    case work
    case rest

    var duration: TimeInterval {
        switch self {
        case .work: return 25 * 60
        case .rest: return 5 * 60
        }
    }

    var next: Phase {
        switch self {
        case .work: return .rest
        case .rest: return .work
        }
    }

    var icon: String {
        switch self {
        case .work: return "🍅"
        case .rest: return "☕"
        }
    }

    var notificationTitle: String {
        switch self {
        case .work: return "Time to focus"
        case .rest: return "Time for a break"
        }
    }

    var notificationBody: String {
        switch self {
        case .work: return "Work session started"
        case .rest: return "Rest session started"
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var startPauseItem: NSMenuItem!
    private var timer: Timer?

    private var phase: Phase = .work
    private var remaining: TimeInterval = Phase.work.duration
    private var running = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        statusItem.menu = buildMenu()

        updateTitle()
    }

    private func buildMenu() -> NSMenu {
        startPauseItem = NSMenuItem(title: "Start", action: #selector(toggleRunning), keyEquivalent: "")
        startPauseItem.target = self

        let resetItem = NSMenuItem(title: "Reset", action: #selector(reset), keyEquivalent: "")
        resetItem.target = self

        let skipItem = NSMenuItem(title: "Skip to next phase", action: #selector(skipPhase), keyEquivalent: "")
        skipItem.target = self

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self

        let menu = NSMenu()
        menu.addItem(startPauseItem)
        menu.addItem(resetItem)
        menu.addItem(skipItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
        return menu
    }

    @objc private func toggleRunning() {
        running.toggle()
        startPauseItem.title = running ? "Pause" : "Start"
        if running {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.tick()
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    @objc private func reset() {
        timer?.invalidate()
        timer = nil
        running = false
        startPauseItem.title = "Start"
        phase = .work
        remaining = phase.duration
        updateTitle()
    }

    @objc private func skipPhase() {
        advancePhase()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func tick() {
        remaining -= 1
        if remaining <= 0 {
            advancePhase()
            notify()
        } else {
            updateTitle()
        }
    }

    private func advancePhase() {
        phase = phase.next
        remaining = phase.duration
        updateTitle()
    }

    private func updateTitle() {
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        statusItem.button?.title = String(format: "%@ %02d:%02d", phase.icon, minutes, seconds)
    }

    private func notify() {
        let notification = NSUserNotification()
        notification.title = phase.notificationTitle
        notification.informativeText = phase.notificationBody
        NSUserNotificationCenter.default.deliver(notification)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
