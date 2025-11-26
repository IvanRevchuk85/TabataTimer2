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
    var body: some View {
        TabView {
            // Training tab — Вкладка "Тренировка"
            NavigationStack {
                ActiveTimerView(config: .default, engine: TimerEngine())
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
    }
}

// MARK: - Placeholder views — Заглушки для вкладок
/// Simple placeholder for Presets until real implementation appears.
/// Простая заглушка для "Пресеты" до появления реальной реализации.
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

/// Simple placeholder for Settings until real implementation appears.
/// Простая заглушка для "Настройки" до появления реальной реализации.
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

// MARK: - Preview — Превью
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}

