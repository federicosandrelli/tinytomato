import AppKit

enum Phase: String {
    case work = "Work"
    case rest = "Rest"
}

func tomatoImage(color: NSColor) -> NSImage {
    let size = NSSize(width: 16, height: 16)
    let image = NSImage(size: size)
    image.lockFocus()

    let body = NSBezierPath(ovalIn: NSRect(x: 1, y: 0, width: 14, height: 13))
    color.setFill()
    body.fill()

    let leaf = NSBezierPath()
    leaf.move(to: NSPoint(x: 8, y: 13))
    leaf.line(to: NSPoint(x: 5, y: 16))
    leaf.line(to: NSPoint(x: 8, y: 14.5))
    leaf.line(to: NSPoint(x: 11, y: 16))
    leaf.close()
    NSColor.systemGreen.setFill()
    leaf.fill()

    image.unlockFocus()
    image.isTemplate = false
    return image
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let workDuration: TimeInterval = 25 * 60
    let restDuration: TimeInterval = 5 * 60

    var statusItem: NSStatusItem!
    var timer: Timer?
    var phase: Phase = .work
    var remaining: TimeInterval = 25 * 60
    var running = false

    var startPauseItem: NSMenuItem!
    var resetItem: NSMenuItem!

    let workColor = NSColor(calibratedRed: 0.90, green: 0.20, blue: 0.16, alpha: 1.0)
    var restColor = NSColor(calibratedRed: 0.298, green: 0.686, blue: 0.314, alpha: 1.0)

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)

        let menu = NSMenu()
        startPauseItem = NSMenuItem(title: "Start", action: #selector(toggleRunning), keyEquivalent: "")
        startPauseItem.target = self
        resetItem = NSMenuItem(title: "Reset", action: #selector(reset), keyEquivalent: "")
        resetItem.target = self
        let skipItem = NSMenuItem(title: "Skip to next phase", action: #selector(skipPhase), keyEquivalent: "")
        skipItem.target = self
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self

        menu.addItem(startPauseItem)
        menu.addItem(resetItem)
        menu.addItem(skipItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)
        statusItem.menu = menu

        updateTitle()
    }

    @objc func toggleRunning() {
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

    @objc func reset() {
        timer?.invalidate()
        timer = nil
        running = false
        startPauseItem.title = "Start"
        phase = .work
        remaining = workDuration
        updateTitle()
    }

    @objc func skipPhase() {
        switchPhase()
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    func tick() {
        remaining -= 1
        if remaining <= 0 {
            switchPhase()
            notify()
        } else {
            updateTitle()
        }
    }

    func switchPhase() {
        phase = (phase == .work) ? .rest : .work
        remaining = (phase == .work) ? workDuration : restDuration
        updateTitle()
    }

    func updateTitle() {
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        statusItem.button?.image = tomatoImage(color: phase == .work ? workColor : restColor)
        statusItem.button?.imagePosition = .imageLeading
        statusItem.button?.title = String(format: "%02d:%02d", minutes, seconds)
    }

    func notify() {
        let notification = NSUserNotification()
        notification.title = phase == .work ? "Time to focus" : "Time for a break"
        notification.informativeText = phase == .work ? "Work session started" : "Rest session started"
        NSUserNotificationCenter.default.deliver(notification)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
