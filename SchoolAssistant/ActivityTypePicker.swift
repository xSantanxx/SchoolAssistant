import SwiftUI

struct ActivityTypePicker: View {
    @Binding var isRegularActivity: Bool

    var body: some View {
        Picker("Activity Type", selection: $isRegularActivity) {
            Text("Class Activity").tag(false)
            Text("Regular Activity").tag(true)
        }
    }
}
