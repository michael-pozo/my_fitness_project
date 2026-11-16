import SwiftUI

/// The Settings tab: save, test and remove the Anthropic API key.
struct SettingsView: View {
    private enum ConnectionStatus: Equatable {
        case idle
        case checking
        case connected(String)
        case failed(String)
    }

    /// e.g. "sk-ant-…x7Qa". Nil when no key is saved. The full key is never shown.
    @State private var savedKeyHint: String?
    @State private var draftKey = ""
    @State private var status = ConnectionStatus.idle
    @State private var errorMessage: String?
    @State private var confirmingRemove = false

    private var trimmedDraft: String {
        draftKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                keySection

                if savedKeyHint != nil {
                    connectionSection
                    Section {
                        Button("Remove Key", role: .destructive) { confirmingRemove = true }
                    }
                }

                Section("About") {
                    LabeledContent("Claude model", value: ClaudeAPI.model)
                    LabeledContent("App version", value: appVersion)
                }
            }
            .navigationTitle("Settings")
            .onAppear(perform: loadSavedKey)
            .confirmationDialog("Remove the API key from this iPhone?", isPresented: $confirmingRemove, titleVisibility: .visible) {
                Button("Remove Key", role: .destructive, action: removeKey)
            } message: {
                Text("The Coach won't work until you add a key again. The key itself stays valid in your Anthropic account.")
            }
            .alert("Couldn't Save Key", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: Sections

    private var keySection: some View {
        Section {
            if let savedKeyHint {
                LabeledContent("Saved key") {
                    Text(savedKeyHint).monospaced()
                }
            }
            SecureField(savedKeyHint == nil ? "Paste your API key" : "Paste a new key to replace it", text: $draftKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit(saveKey)
            Button(savedKeyHint == nil ? "Save Key" : "Replace Key", action: saveKey)
                .disabled(trimmedDraft.isEmpty)
        } header: {
            Text("Anthropic API Key")
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                Text("Stored only in this iPhone's secure Keychain: never in the app's code, synced, or backed up.")
                Link("Get a key at console.anthropic.com", destination: URL(string: "https://console.anthropic.com")!)
            }
        }
    }

    private var connectionSection: some View {
        Section {
            Button {
                Task { await testConnection() }
            } label: {
                HStack {
                    Text("Test Connection")
                    Spacer()
                    if status == .checking { ProgressView() }
                }
            }
            .disabled(status == .checking)

            switch status {
            case .idle, .checking:
                EmptyView()
            case .connected(let modelName):
                Label("Connected to \(modelName)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        } footer: {
            Text("The test is free; it doesn't use any tokens.")
        }
    }

    // MARK: Actions

    private func loadSavedKey() {
        #if DEBUG
        // Simulator testing: `-fakeAPIKey` saves an invalid key and tests it (expect "isn't valid").
        if ProcessInfo.processInfo.arguments.contains("-fakeAPIKey"), savedKeyHint == nil {
            try? KeychainStore.save("sk-ant-FAKE-key-for-testing-0000", for: .anthropicAPIKey)
            savedKeyHint = KeychainStore.read(.anthropicAPIKey).map(Self.hint(for:))
            Task { await testConnection() }
            return
        }
        #endif
        savedKeyHint = KeychainStore.read(.anthropicAPIKey).map(Self.hint(for:))
    }

    private func saveKey() {
        let key = trimmedDraft
        guard !key.isEmpty else { return }
        do {
            try KeychainStore.save(key, for: .anthropicAPIKey)
            draftKey = ""
            loadSavedKey()
            Task { await testConnection() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func removeKey() {
        do {
            try KeychainStore.delete(.anthropicAPIKey)
            savedKeyHint = nil
            status = .idle
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func testConnection() async {
        guard let api = ClaudeAPI.fromKeychain() else {
            status = .failed("No API key saved.")
            return
        }
        status = .checking
        do {
            status = .connected(try await api.checkConnection())
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    // MARK: Helpers

    /// Shows only the start and last 4 characters, e.g. "sk-ant-…x7Qa".
    static func hint(for key: String) -> String {
        let prefix = key.hasPrefix("sk-ant-") ? "sk-ant-" : String(key.prefix(4))
        return "\(prefix)…\(key.suffix(4))"
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
}
