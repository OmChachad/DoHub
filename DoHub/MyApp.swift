import SwiftData
import SwiftUI

@main struct MyApp: App {
    private let container: ModelContainer
    private let runner: ShortcutRunner

    init() {
        do {
            container = try ModelContainer(for: ShortcutTile.self, ShortcutRunRecord.self)
        } catch {
            fatalError("Couldn’t open the DoHub store: \(error)")
        }
        runner = ShortcutRunner(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(runner)
                .onOpenURL { url in
                    withAnimation(.smooth) {
                        runner.handleCallback(url)
                    }
                }
        }
        .modelContainer(container)
    }
}
