import SwiftUI

@main
struct SproutMobileSampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Sprout Mobile Sample")
                .font(.title)
            Text("Link test: XCFramework + UniFFI Swift bindings")
                .font(.subheadline)
        }
        .padding()
    }
}
