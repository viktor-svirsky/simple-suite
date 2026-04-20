import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.syncStatus) private var sync
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("iCloud") {
                LabeledContent("Status", value: statusText)
                if case .disabled = sync.state {
                    Text("This build has iCloud sync disabled. Install from TestFlight to enable.")
                        .font(Theme.Font.sans(13))
                        .foregroundStyle(Theme.Color.muted)
                }
                Button("Open iCloud Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            Section("About") {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Bundle", value: Bundle.main.bundleIdentifier ?? "—")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    private var statusText: String {
        switch sync.state {
        case .disabled: return "Disabled (build flag off)"
        case .offline: return "Offline"
        case .syncing: return "Syncing…"
        case .synced(let date):
            let f = RelativeDateTimeFormatter()
            return "Synced · " + f.localizedString(for: date, relativeTo: Date())
        }
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(v) (\(b))"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(\.syncStatus, SyncStatus(state: .disabled))
    }
}
