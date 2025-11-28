//
//  ActiveTimerView.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import SwiftUI

// MARK: - ActiveTimerView — Экран активной тренировки
/// Main screen that displays the active timer session and controls.
/// Основной экран, отображающий активную сессию таймера и элементы управления.
struct ActiveTimerView: View {

    // MARK: ViewModel — Модель представления
    @StateObject private var viewModel: ActiveTimerViewModel

    // MARK: Local UI state for animations — Локальное состояние для анимаций
    /// Pulse flag toggled on phase changes (scale/pulse micro-animation).
    /// Флаг пульса, переключается при смене фазы (микро‑анимация масштаба).
    @State private var phasePulse: Bool = false

    /// Ring pulse for 3‑2‑1 countdown (no numeric overlay).
    /// Пульс кольца на обратном отсчёте 3‑2‑1 (без числового оверлея).
    @State private var ringPulse: Bool = false

    // MARK: Sizing — Размеры
    /// Диаметр кольца (адаптивно можно вынести в Theme или настройки).
    private let ringDiameter: CGFloat = 240
    /// Адаптивный размер цифры как доля диаметра кольца.
    /// 0.8 даёт хорошую читаемость и не пересекает толстую дугу.
    private var countdownFontSize: CGFloat { ringDiameter * 0.8 }

    // MARK: Init — Инициализация
    init(config: TabataConfig = .default, engine: TimerEngineProtocol = TimerEngine()) {
        _viewModel = StateObject(wrappedValue: ActiveTimerViewModel(config: config, engine: engine))
    }

    // MARK: - Body — Тело
    var body: some View {
        VStack(spacing: 0) {
            // Верхняя текстовая часть
            VStack(spacing: 24) {
                // Phase title — Заголовок фазы
                PhaseTitleView(phase: viewModel.state.currentPhase)
                    // Micro pulse on phase change — Микро‑пульс при смене фазы
                    .scaleEffect(phasePulse ? 1.06 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.65), value: phasePulse)

                // Big timer — Крупный таймер (мм:сс)
                Text(formattedTime(viewModel.state.remainingTime))
                    .font(.system(size: Theme.Typography.titleXL, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.theme(.textPrimary))
                    // Пульсация как у кольца:
                    // при смене фазы — 1.06
                    .scaleEffect(phasePulse ? 1.06 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: phasePulse)
                    // на обратном отсчёте 3‑2‑1 — 1.16
                    .scaleEffect(ringPulse ? 1.16 : 1.0)
                    .animation(.easeOut(duration: 0.18), value: ringPulse)
                    .accessibilityLabel("Remaining time")
                    .accessibilityValue("\(viewModel.state.remainingTime) seconds")

                // Set/Cycle indicator — Индикатор сета/цикла
                Text("Set \(viewModel.state.currentSet)/\(viewModel.state.totalSets) • Cycle \(viewModel.state.currentCycle)/\(viewModel.state.totalCyclesPerSet)")
                    .font(.system(size: Theme.Typography.titleM, weight: .semibold))
                    .foregroundStyle(Color.theme(.textSecondary))
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 24)

            // Центрированное по горизонтали кольцо прогресса + цифры 3-2-1 в центре
            Spacer(minLength: 16)
            ZStack {
                CircularProgressView(
                    progress: viewModel.state.progress,
                    tint: Color.forPhase(viewModel.state.currentPhase),
                    trackTint: Color.theme(.progressTrack),
                    lineWidth: 24 // удвоенная толщина
                )
                // Увеличенная пульсация как договорились:
                .scaleEffect(phasePulse ? 1.06 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.75), value: phasePulse)
                .scaleEffect(ringPulse ? 1.16 : 1.0)
                .animation(.easeOut(duration: 0.18), value: ringPulse)

                // Оверлей цифр 3-2-1
                if let countdownNumber = countdownOverlayNumber() {
                    Text("\(countdownNumber)")
                        .font(.system(size: countdownFontSize, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.5) // подстраховка на малых экранах
                        .lineLimit(1)
                        .foregroundStyle(Color.forPhase(viewModel.state.currentPhase))
                        // Синхронная пульсация с кольцом
                        .scaleEffect(phasePulse ? 1.06 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: phasePulse)
                        .scaleEffect(ringPulse ? 1.16 : 1.0)
                        .animation(.easeOut(duration: 0.18), value: ringPulse)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .accessibilityHidden(true)
                }
            }
            .frame(width: ringDiameter, height: ringDiameter)
            .frame(maxWidth: .infinity, alignment: .center) // равномерные отступы слева/справа
            // Явная анимация появления/исчезновения цифр по value: remainingTime
            .animation(.easeOut(duration: 0.18), value: viewModel.state.remainingTime)

            // Spacer, чтобы кольцо оказалось по вертикали между текстом и кнопками
            Spacer(minLength: 16)

            // Controls — Панель управления
            ControlsBar(
                state: viewModelState(),
                onStart: { viewModel.start() },
                onPause: { viewModel.pause() },
                onResume: { viewModel.resume() },
                onReset: { viewModel.reset() }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.theme(.bgPrimary))
        .navigationTitle("Training")
        .navigationBarTitleDisplayMode(.inline)
        // Trigger micro‑animation on phase change — Триггерим микро‑анимацию при смене фазы
        .onChange(of: viewModel.state.currentPhase) { _ in
            phasePulse.toggle()
        }
        // Pulse ring on visual countdown 3‑2‑1 (no numeric overlay)
        // Пульс кольца на обратном отсчёте 3‑2‑1 (без чисел)
        .onChange(of: viewModel.state.remainingTime) { newValue in
            handleRingPulseForCountdown(newValue)
        }
    }

    // MARK: - Helpers — Вспомогательные методы
    private func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// 3-2-1 overlay number for remaining time; nil when not in countdown window.
    private func countdownOverlayNumber() -> Int? {
        let r = viewModel.state.remainingTime
        return (1...3).contains(r) ? r : nil
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
        if viewModel.state.currentPhase == .finished || viewModel.state.progress >= 1.0 {
            return .finished
        }
        if viewModel.state.remainingTime > 0 && viewModel.state.progress > 0 {
            return .running
        }
        return .idle
    }

    // MARK: - Ring pulse logic — Пульс кольца на обратном отсчёте
    private func handleRingPulseForCountdown(_ remaining: Int) {
        guard (1...3).contains(remaining) else { return }
        ringPulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            ringPulse = false
        }
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
