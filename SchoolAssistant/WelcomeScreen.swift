import SwiftUI

struct WelcomeScreen: View {
    @AppStorage("userName") private var userName = ""
    @State private var name = ""

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section {
                Text("Welcome to SchoolAssistant")
                    .font(.title2)
                Text("What should we call you?")
                TextField("Your name", text: $name)
                    .onSubmit(saveName)
                Text("Enter 1–12 characters. Spaces alone don’t count.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button("Get Started", action: saveName)
                .disabled(trimmedName.isEmpty || trimmedName.count > 12)
        }
        .navigationTitle("Welcome")
    }

    private func saveName() {
        guard !trimmedName.isEmpty, trimmedName.count <= 12 else { return }
        userName = trimmedName
    }
}

#Preview {
    WelcomeScreen()
}
