//
//  RootView.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import SwiftUI

// MARK: - RootView — Корневой экран с навигацией (TabView)
struct RootView: View {

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isRunningUnitTests) private var isRunningUnitTests

    // Timer/VM/notifications
    @State private var engine = TimerEngine()
    @StateObject private var viewModel = ActiveTimerViewModel(config: .default, engine: TimerEngine())
    @State private var notificationService = NotificationService()
    @State private var coordinator: BackgroundTimerCoordinator?

    // Settings for theme
    @State private var settings: AppSettings = .default

    var body: some View {
        TabView {
            // Training
            NavigationStack {
                ActiveTimerView(config: .default, engine: engine)
                    .navigationTitle("Training")
            }
            .tabItem { Label("Training", systemImage: "stopwatch.fill") }

            // Presets
            NavigationStack {
                PresetsView(store: PresetsStore())
                    .navigationTitle("Presets")
            }
            .tabItem { Label("Presets", systemImage: "list.bullet") }

            // Settings
            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        // Применение темы
        .preferredColorScheme(colorScheme(from: settings.theme))
        .task {
            // Не выполнять фоновые действия в юнит‑тестах
            if !isRunningUnitTests {
                _ = try? await notificationService.requestAuthorization()
                if coordinator == nil {
                    coordinator = BackgroundTimerCoordinator(
                        notifications: notificationService,
                        planProvider: { TabataPlan.build(from: .default) },
                        positionProvider: {
                            let s = viewModel.state
                            let isRunning = true
                            return (s.currentIntervalIndex, s.remainingTime, isRunning)
                        },
                        onReconcile: { _, _, _ in }
                    )
                }
            }
            // Загрузка настроек для темы
            if let loaded = try? await SettingsStore().load() {
                settings = loaded
            } else {
                settings = .default
            }
        }
        .onChange(of: scenePhase) { phase in
            guard let coordinator, !isRunningUnitTests else { return }
            Task {
                switch phase {
                case .background:
                    await coordinator.handleDidEnterBackground()
                case .active:
                    await coordinator.handleDidBecomeActive()
                default:
                    break
                }
            }
        }
        // Обновлять схему при изменении темы в рантайме (если SettingsView меняет и сохраняет)
        .onReceive(NotificationCenter.default.publisher(for: .init("AppSettingsThemeDidChange"))) { _ in
            Task {
                if let loaded = try? await SettingsStore().load() {
                    settings = loaded
                }
            }
        }
    }

    // Map AppSettings.Theme to SwiftUI ColorScheme?
    private func colorScheme(from theme: AppSettings.Theme) -> ColorScheme? {
        switch theme {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
