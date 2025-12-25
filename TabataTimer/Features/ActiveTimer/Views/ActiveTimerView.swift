//
//  ActiveTimerView.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import SwiftUI
import UIKit

import SwiftUI

// MARK: - ActiveTimerView — Main training screen / Экран активной тренировки
struct ActiveTimerView: View {

    @Environment(\.isRunningUnitTests) private var isRunningUnitTests
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: ActiveTimerViewModel

    // MARK: Visual state / Визуальное состояние
    @State private var phasePulse: Bool = false
    @State private var ringPulse: Bool = false

    // MARK: Floating phrase state / Состояние всплывающей фразы
    @State private var phraseText: String?
    @State private var showPhrase: Bool = false
    @State private var phrasePulse: Bool = false

    // MARK: Timer state flags / Флаги состояния таймера
    @State private var hasStarted: Bool = false
    @State private var isPaused: Bool = false

    // MARK: Workout plan sheet
    @State private var isShowingPlan: Bool = false

    // MARK: Layout constants / Константы лейаута
    private let ringDiameter: CGFloat = 240
    private var countdownFontSize: CGFloat { ringDiameter * 0.8 }

    @State private var settings: AppSettings

    // MARK: Init
    /// Inject shared ActiveTimerViewModel (single source of truth).
    /// Внедряем общую ActiveTimerViewModel (единый источник правды).
    init(viewModel: ActiveTimerViewModel, settings: AppSettings) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _settings = State(initialValue: settings)
    }

    // MARK: Body
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height

            Group {
                if isLandscape {
                    // MARK: Landscape layout / Ландшафтный режим
                    HStack(spacing: 16) {
                        ringBlock
                            .frame(width: ringDiameter, height: ringDiameter)
                            .frame(maxHeight: .infinity)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .offset(x: -50) // fine-tune: слегка сдвигаем кольцо влево в горизонтали

                        VStack(spacing: 0) {
                            VStack(spacing: 10) {
                                headerBlock(isLandscape: true)
                                Button {
                                    isShowingPlan = true
                                } label: {
                                    setCycleLabel
                                }
                                .buttonStyle(.plain)
                                // LANDSCAPE: disable phrases — не показываем фразы в ландшафтном режиме
                                EmptyView()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .offset(y: -16)

                            Spacer(minLength: 0)

                            ControlsBar(
                                state: viewModelState(),
                                onStart: {
                                    hasStarted = true
                                    isPaused = false
                                    // LANDSCAPE: do not show phrase on start
                                    viewModel.start()
                                },
                                onPause: {
                                    isPaused = true
                                    viewModel.pause()
                                },
                                onResume: {
                                    isPaused = false
                                    viewModel.resume()
                                },
                                onReset: {
                                    hasStarted = false
                                    isPaused = false
                                    // LANDSCAPE: ensure phrase hidden (safety)
                                    hidePhrase()
                                    viewModel.reset()
                                }
                            )
                            .padding(.horizontal, 10)
                            .padding(.bottom, 16)
                            .offset(y: 3)
                            .offset(x: -40)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // MARK: Portrait layout / Портретный режим
                    VStack(spacing: 0) {
                        headerBlock(isLandscape: false)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 24)

                        Button {
                            isShowingPlan = true
                        } label: {
                            setCycleLabel
                                .padding(.top, 4)
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 0)

                        // Портретный: показываем фразы
                        phraseView
                            .padding(.bottom, 5)

                        Spacer(minLength: 0)

                        ringBlock
                            .frame(width: ringDiameter, height: ringDiameter)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .animation(.easeOut(duration: 0.18), value: viewModel.state.remainingTime)

                        Spacer(minLength: 0)

                        ControlsBar(
                            state: viewModelState(),
                            onStart: {
                                hasStarted = true
                                isPaused = false
                                showInitialPhasePhraseOnStart()
                                viewModel.start()
                            },
                            onPause: {
                                viewModel.pause()
                                isPaused = true
                            },
                            onResume: {
                                viewModel.resume()
                                isPaused = false
                            },
                            onReset: {
                                hasStarted = false
                                isPaused = false
                                hidePhrase()
                                viewModel.reset()
                            }
                        )
                        .padding(.horizontal, 10)
                        .padding(.bottom, 16)
                    }
                }
            }
            // MARK: Orientation-aware side effects / Побочные эффекты c учётом ориентации

            .onChange(of: viewModel.state.currentPhase) { newPhase in
                phasePulse.toggle()
                guard viewModel.isRunning else { return }
                if !isLandscape { // только в портретном
                    showPhasePhrase(for: newPhase)
                } else {
                    hidePhrase()
                }
            }

            .onChange(of: viewModel.state.remainingTime) { newValue in
                handleRingPulseForCountdown(newValue)
                if !isLandscape { // только в портретном
                    handlePhrasePulseForCountdown(newValue)
                } else {
                    phrasePulse = false
                }
            }

            .onReceive(NotificationCenter.default.publisher(for: .tabataAutoStartRequested)) { _ in
                if settings.autoStartFromPreset {
                    hasStarted = true
                    isPaused = false
                    if !isLandscape {
                        showInitialPhasePhraseOnStart()
                    } else {
                        hidePhrase()
                    }
                    viewModel.start()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .appSettingsDidChange)) { _ in
                Task {
                    let loaded = (try? await SettingsStore().load()) ?? .default
                    settings = loaded

                    // Если фразы выключили — мгновенно скрываем текущую
                    if !settings.inWorkoutPhrasesEnabled {
                        hidePhrase()
                    }
                }
            }
            .onChange(of: viewModel.sessionTitle) { _ in
                // Reset only when engine is idle (new preset applied before start).
                // Сбрасываем только когда движок idle (пресет применился ДО старта).
                guard !viewModel.isRunning, !viewModel.isPaused else { return }
                hasStarted = false
                isPaused = false
                hidePhrase()
            }
            .onChange(of: viewModel.state.totalDuration) { _ in
                guard !viewModel.isRunning, !viewModel.isPaused else { return }
                hasStarted = false
                isPaused = false
                hidePhrase()
            }

            // При смене ориентации на ландшафтную — скрыть фразу
            .onChange(of: isLandscape) { nowLandscape in
                if nowLandscape {
                    hidePhrase()
                }
            }
        }
        /// Applies user-selected light mode background if needed.
        /// Применяет выбранный пользователем фон для светлого режима (если требуется).
        .background(Color.appBackground(settings: settings, colorScheme: colorScheme))
        .navigationTitle(viewModel.sessionTitle)
        .navigationBarTitleDisplayMode(.inline)

        .onDisappear {
            guard !isRunningUnitTests else { return }
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Phrase view — text only / Вью фразы (только текст)

    @ViewBuilder
    private var phraseView: some View {
        if showPhrase, let text = phraseText {
            Text(text)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.forPhase(viewModel.state.currentPhase))
                .minimumScaleFactor(0.4)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .scaleEffect(phrasePulse ? 1.16 : 1.0)
                .animation(.easeOut(duration: 0.18), value: phrasePulse)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity
                    )
                )
                .animation(.spring(response: 0.25, dampingFraction: 0.85), value: showPhrase)
                .accessibilityHidden(true)
        }
    }

    // MARK: Phrase handling / Логика показа фразы

    private func showPhasePhrase(for phase: TabataPhase) {
        guard settings.inWorkoutPhrasesEnabled else { return }

        let lang = resolveLanguage()
        phraseText = PhraseRepository.randomPhrase(
            for: phase,
            lang: lang,
            excluding: phraseText   // избегаем последней показанной фразы
        )
        withAnimation {
            showPhrase = phraseText != nil
        }
        phrasePulse = false
    }

    private func showInitialPhasePhraseOnStart() {
        guard settings.inWorkoutPhrasesEnabled else { return }

        // Prefer the real first phase of the current plan.
        // Берём реальную первую фазу текущего плана.
        let initialPhase = viewModel.currentPlan.first?.phase ?? viewModel.state.currentPhase
        showPhasePhrase(for: initialPhase)
    }

    private func hidePhrase() {
        withAnimation {
            showPhrase = false
        }
        phraseText = nil
        phrasePulse = false
    }

    private func handlePhrasePulseForCountdown(_ remaining: Int) {
        guard (1...3).contains(remaining) else { return }
        phrasePulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            phrasePulse = false
        }
    }

    private func resolveLanguage() -> PhraseRepository.Lang {
        let code = Locale.current.language.languageCode?.identifier.lowercased() ?? "en"
        switch code {
        case "ru": return .ru
        case "uk": return .uk
        case "es": return .es
        default:   return .en
        }
    }

    // MARK: - Layout subviews / Подвью для лейаута

    private func headerBlock(isLandscape: Bool) -> some View {
        VStack(spacing: 16) {
            PhaseTitleView(phase: viewModel.state.currentPhase)
                .scaleEffect(phasePulse ? 1.06 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.65), value: phasePulse)

            Text(formattedTime(viewModel.state.remainingTime))
                .font(
                    .system(
                        size: DesignTokens.Typography.titleXL * 1.5,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .monospacedDigit()
                .foregroundStyle(Color.theme(.textPrimary))
                .scaleEffect(phasePulse ? 1.06 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: phasePulse)
                .scaleEffect(ringPulse ? 1.16 : 1.0)
                .animation(.easeOut(duration: 0.18), value: ringPulse)
                .accessibilityLabel("Remaining time")
                .accessibilityValue("\(viewModel.state.remainingTime) seconds")
        }
        .offset(y: isLandscape ? -3 : 0)
    }

    private var setCycleLabel: some View {
        Text(
            "Set \(viewModel.state.currentSet)/\(viewModel.state.totalSets) • " +
            "Cycle \(viewModel.state.currentCycle)/\(viewModel.state.totalCyclesPerSet)"
        )
        .font(.system(size: DesignTokens.Typography.titleM, weight: .semibold))
        .foregroundStyle(Color.theme(.textSecondary))
    }

    private var ringBlock: some View {
        ZStack {
            CircularProgressView(
                progress: viewModel.state.progress,
                tint: Color.forPhase(viewModel.state.currentPhase),
                trackTint: Color.theme(.progressTrack),
                lineWidth: 24
            )
            .scaleEffect(phasePulse ? 1.06 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: phasePulse)
            .scaleEffect(ringPulse ? 1.16 : 1.0)
            .animation(.easeOut(duration: 0.18), value: ringPulse)

            if let countdownNumber = countdownOverlayNumber() {
                Text("\(countdownNumber)")
                    .font(.system(size: countdownFontSize, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(Color.forPhase(viewModel.state.currentPhase))
                    .scaleEffect(phasePulse ? 1.06 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.75), value: phasePulse)
                    .scaleEffect(ringPulse ? 1.16 : 1.0)
                    .animation(.easeOut(duration: 0.18), value: ringPulse)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: - Helpers

    private func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func countdownOverlayNumber() -> Int? {
        let r = viewModel.state.remainingTime
        return (1...3).contains(r) ? r : nil
    }

    private func viewModelState() -> ControlsBar.State {
        if viewModel.state.currentPhase == .finished || viewModel.state.progress >= 1.0 {
            return .finished
        }
        if viewModel.isPaused { return .paused }
        if viewModel.isRunning { return .running }
        return .idle
    }

    private func handleRingPulseForCountdown(_ remaining: Int) {
        guard (1...3).contains(remaining) else { return }
        ringPulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            ringPulse = false
        }
    }
    
}

// MARK: - Preview / Превью
struct ActiveTimerView_Previews: PreviewProvider {
    static var previews: some View {
        let engine = TimerEngine()
        let vm = ActiveTimerViewModel(config: .default, engine: engine)
        return Group {
            NavigationStack {
                ActiveTimerView(viewModel: vm, settings: .default)
            }
            .previewDisplayName("Portrait")

            NavigationStack {
                ActiveTimerView(viewModel: vm, settings: .default)
            }
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDisplayName("Landscape")
        }
    }
}

