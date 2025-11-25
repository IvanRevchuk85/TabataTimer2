//
//  ActiveTimerView.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 25.11.2025.
//

import SwiftUI

// MARK: - ActiveTimerView — Экран активной тренировки
/// Main screen that displays the active timer session and controls.
/// Основной экран, отображающий активную сессию таймера и элементы управления.
struct ActiveTimerView: View {

    // MARK: ViewModel — Модель представления
    @StateObject private var viewModel: ActiveTimerViewModel

    // MARK: Init — Инициализация
    init(config: TabataConfig = .default, engine: TimerEngineProtocol = TimerEngine()) {
        _viewModel = StateObject(wrappedValue: ActiveTimerViewModel(config: config, engine: engine))
    }

    // MARK: - Body — Тело
    var body: some View {
        VStack(spacing: 24) {
            // Phase title — Заголовок фазы
            PhaseTitleView(phase: viewModel.state.currentPhase)

            // Big timer — Крупный таймер (мм:сс)
            Text(formattedTime(viewModel.state.remainingTime))
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
                .accessibilityLabel("Remaining time")
                .accessibilityValue("\(viewModel.state.remainingTime) seconds")

            // Set/Cycle indicator — Индикатор сета/цикла
            Text("Set \(viewModel.state.currentSet)/\(viewModel.state.totalSets) • Cycle \(viewModel.state.currentCycle)/\(viewModel.state.totalCyclesPerSet)")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Circular progress — Круговой прогресс
            CircularProgressView(progress: viewModel.state.progress)
                .frame(width: 160, height: 160)
                .padding(.top, 8)

            Spacer(minLength: 8)

            // Controls — Панель управления
            ControlsBar(
                state: viewModelState(),
                onStart: { viewModel.start() },
                onPause: { viewModel.pause() },
                onResume: { viewModel.resume() },
                onReset: { viewModel.reset() }
            )
        }
        .padding(24)
        .navigationTitle("Tabata Timer")
        .navigationBarTitleDisplayMode(.inline)
        // MARK: - Layout, Controls, Bindings
        // Layout stacks above, controls wired to ViewModel methods, bindings via @StateObject.
        // Лейаут через VStack, кнопки привязаны к методам ViewModel, биндинги через @StateObject.
    }

    // MARK: - Helpers — Вспомогательные методы
    private func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// Map engine state to simple UI state for controls.
    /// Маппинг состояния движка в простое UI-состояние для кнопок.
    private func viewModelState() -> ControlsBar.State {
        switch viewModelStateRaw() {
        case .idle: return .idle
        case .running: return .running
        case .paused: return .paused
        case .finished: return .finished
        }
    }

    private func viewModelStateRaw() -> TimerState {
        // Мы не имеем прямого доступа к engine.state из VM,
        // поэтому ориентируемся по фазе/прогрессу.
        // We don’t read engine.state directly; infer via phase/progress.
        if viewModel.state.currentPhase == .finished || viewModel.state.progress >= 1.0 {
            return .finished
        }
        // Простейшая эвристика: если осталось время > 0 и прогресс > 0 — считаем активным.
        // Simple heuristic: if remaining > 0 and progress > 0, consider active.
        if viewModel.state.remainingTime > 0 && viewModel.state.progress > 0 {
            return .running
        }
        // Если remaining уменьшается только после старта — до первого тика считаем idle.
        // Before first tick we’re likely idle.
        return .idle
    }
}

// MARK: - Preview — Превью
struct ActiveTimerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ActiveTimerView(config: .default, engine: TimerEngine())
        }
    }
}

