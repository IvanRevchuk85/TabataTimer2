//
//  RootView.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import SwiftUI

// MARK: - RootView — Корневой экран с навигацией (TabView)
// Main application container with tabs: Training, Presets, Settings.
// Корневой контейнер приложения с вкладками: Тренировка, Пресеты, Настройки.
struct RootView: View {

    @Environment(\.scenePhase) private var scenePhase

    // Shared engine + VM for Training tab so we can coordinate background behavior.
    // Общие движок и VM для вкладки Тренировка, чтобы координировать фон.
    @State private var engine = TimerEngine()
    @StateObject private var viewModel = ActiveTimerViewModel(config: .default, engine: TimerEngine())

    // Notification service and background coordinator.
    // Сервис уведомлений и координатор фона.
    @State private var notificationService = NotificationService()
    @State private var coordinator: BackgroundTimerCoordinator?

    var body: some View {
        TabView {
            // Training tab — Вкладка "Тренировка"
            NavigationStack {
                ActiveTimerView(config: .default, engine: engine)
                    .navigationTitle("Training")
            }
            .tabItem {
                Label("Training", systemImage: "stopwatch.fill")
            }

            // Presets tab (placeholder) — Вкладка "Пресеты" (заглушка)
            NavigationStack {
                PresetsPlaceholderView()
                    .navigationTitle("Presets")
            }
            .tabItem {
                Label("Presets", systemImage: "list.bullet")
            }

            // Settings tab (placeholder) — Вкладка "Настройки" (заглушка)
            NavigationStack {
                SettingsPlaceholderView()
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .task {
            // Request permissions once on first appearance.
            // Запрашиваем разрешения один раз при первом появлении.
            _ = try? await notificationService.requestAuthorization()

            // Build coordinator once.
            // Создаём координатор один раз.
            if coordinator == nil {
                coordinator = BackgroundTimerCoordinator(
                    notifications: notificationService,
                    planProvider: { TabataPlan.build(from: .default) },
                    positionProvider: {
                        // Позицию берём из VM state. Здесь для простоты используем дефолтную VM.
                        let s = viewModel.state
                        let isRunning = true // упрощение: можно расширить VM для отдачи статуса
                        return (s.currentIntervalIndex, s.remainingTime, isRunning)
                    },
                    onReconcile: { newIndex, newRemaining, finished in
                        // Временно: ничего не делаем с движком, UI сам догонит по тикам.
                        // Лучше расширить движок методом fastForward(to:remaining:).
                        if finished {
                            // Можно инициировать завершение/сброс при необходимости.
                        } else {
                            // Здесь можно уведомить VM о необходимости ресинка.
                        }
                    }
                )
            }
        }
        .onChange(of: scenePhase) { phase in
            guard let coordinator else { return }
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
    }
}

// MARK: - Placeholder views — Заглушки для вкладок
private struct PresetsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Presets will be here")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

private struct SettingsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Settings will be here")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
