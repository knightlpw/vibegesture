import AppKit

autoreleasepool {
    let delegate = ApplicationDelegate()
    let application = NSApplication.shared
    application.delegate = delegate
    application.setActivationPolicy(.accessory)
    application.run()
}
