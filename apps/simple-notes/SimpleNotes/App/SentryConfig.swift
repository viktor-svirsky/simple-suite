import Foundation
import Sentry

enum SentryConfig {
    /// Starts Sentry if a DSN is present in Info.plist (stamped at build time via
    /// the `SENTRY_DSN` build setting). No-op otherwise — local dev builds have no DSN.
    static func start(environment: String, release: String) {
        guard
            let dsn = Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String,
            !dsn.isEmpty,
            !dsn.hasPrefix("$(")
        else {
            return
        }

        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = environment
            options.releaseName = release
            options.tracesSampleRate = 0.01
            options.attachScreenshot = false
            options.attachViewHierarchy = false
            options.beforeSend = { event in
                event.tags = (event.tags ?? [:])
                    .merging(["cloudkit": Self.cloudKitEnabled ? "1" : "0"], uniquingKeysWith: { a, _ in a })
                return event
            }
        }
    }

    static var release: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        return "simple-notes@\(version)"
    }

    static var environment: String {
        #if DEBUG
        return "development"
        #else
        return "production"
        #endif
    }

    static var cloudKitEnabled: Bool {
        #if SIMPLE_NOTES_CLOUDKIT_ENABLED
        return true
        #else
        return false
        #endif
    }
}
