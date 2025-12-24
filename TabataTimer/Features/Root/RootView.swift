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
    @Environment(\.colorScheme) private var colorScheme

    // MARK: Shared engine & VM — один общий движок и одна общая VM
    @State private var sharedEngine = TimerEngine()
    @StateObject private var sharedViewModel: ActiveTimerViewModel

    // Notifications / background coordination
    @State private var notificationService = NotificationService()
    @State private var coordinator: BackgroundTimerCoordinator?

    // Settings for theme
    @State private var settings: AppSettings = .default

    // Tab selection (optional: to switch to Training after preset apply)
    @State private var selectedTab: Int = 0

    // MARK: - Init to ensure sharedViewModel uses sharedEngine
    init() {
        // Создаём один общий движок и на его основе — одну общую VM.
        let engine = TimerEngine()
        _sharedEngine = State(initialValue: engine)
        _sharedViewModel = StateObject(wrappedValue: ActiveTimerViewModel(config: .default, engine: engine))
    }
    
    private var effectiveColorScheme: ColorScheme {
        // If app forces theme, use it for background too; otherwise use env.
        // Если тема принудительная — используем её и для фона; иначе env.
        colorScheme(from: settings.theme) ?? colorScheme
    }

    var body: some View {
        ZStack {
            Color.appBackground(settings: settings, colorScheme: effectiveColorScheme)
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                // Training
                NavigationStack {
                    // Передаём единую VM в экран тренировки.
                    ActiveTimerView(viewModel: sharedViewModel, settings: settings)
                }
                .tabItem { Label("Training", systemImage: "stopwatch.fill") }
                .tag(0)

                // Presets
                NavigationStack {
                    // onSelect: (preset, autoStart) → applyConfig + переключить вкладку на Training
                    PresetsView(store: PresetsStore()) { preset, autoStart in
                        sharedViewModel.applyConfig(
                            preset.config,
                            title: preset.name,
                            autoStart: autoStart
                        )
                        selectedTab = 0
                    }
                    .navigationTitle("Presets")
                }
                .tabItem { Label("Presets", systemImage: "list.bullet") }
                .tag(1)

                // Settings
                NavigationStack {
                    SettingsView()
                        .navigationTitle("Settings")
                }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
            }
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
                        planProvider: { sharedViewModel.currentPlan },
                        positionProvider: {
                            let s = sharedViewModel.state
                            return (s.currentIntervalIndex, s.remainingTime, sharedViewModel.isRunning)
                        },
                        onReconcile: { newIndex, newRemaining, finished in
                            sharedViewModel.reconcilePosition(newIndex: newIndex, newRemaining: newRemaining, finished: finished)
                        }
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
        .onReceive(NotificationCenter.default.publisher(for: .appSettingsDidChange)) { _ in
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

