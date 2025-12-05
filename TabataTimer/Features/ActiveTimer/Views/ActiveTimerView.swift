//
//  ActiveTimerView.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import SwiftUI
import UIKit

// MARK: - PhraseRepository — Humorous phrases per phase / Набор фраз по фазам
private enum PhraseRepository {

    // Supported languages (auto-selected by locale). / Поддерживаемые языки.
    enum Lang: String { case en, ru, uk, es }

    /// Returns random phrase for given phase and language.
    /// Возвращает случайную фразу для указанной фазы и языка.
    static func randomPhrase(for phase: TabataPhase, lang: Lang) -> String? {
        let pool: [String]

        switch (phase, lang) {
        // PREPARE
        case (.prepare, .en): pool = [
            "Last chance to quit",
            "Breathe in…",
            "Warm up your will",
            "No excuses today",
            "Ready or not…"
        ]
        case (.prepare, .ru): pool = [
            "Последний шанс передумать",
            "Вдохни глубже…",
            "Разминай силу воли",
            "Без отмаз сегодня",
            "Готов — не готов…"
        ]
        case (.prepare, .uk): pool = [
            "Останній шанс передумати",
            "Вдихни глибше…",
            "Розігрій силу волі",
            "Без відмаз сьогодні",
            "Готовий чи ні…"
        ]
        case (.prepare, .es): pool = [
            "Última oportunidad de rendirte",
            "Inhala profundo…",
            "Calienta tu voluntad",
            "Sin excusas hoy",
            "Listo o no…"
        ]

        // WORK
        case (.work, .en): pool = [
            "Push, don’t negotiate",
            "You asked for this",
            "Legs are lying",
            "This is the rep that counts",
            "Don’t be average",
            "Pain is data",
            "You can rest later"
        ]
        case (.work, .ru): pool = [
            "Жми, не торгуйся",
            "Ты сам этого хотел",
            "Ноги врут, продолжай",
            "Вот этот подход и считается",
            "Не будь средним",
            "Боль — это просто данные",
            "Отдохнёшь потом"
        ]
        case (.work, .uk): pool = [
            "Тисни, не торгуйся",
            "Ти сам цього хотів",
            "Ноги брешуть",
            "Саме цей підхід має значення",
            "Не будь середнім",
            "Біль — це просто дані",
            "Відпочинеш потім"
        ]
        case (.work, .es): pool = [
            "Empuja, no negocies",
            "Tú pediste esto",
            "Las piernas mienten",
            "Esta es la repetición que cuenta",
            "No seas promedio",
            "El dolor es información",
            "Descansarás luego"
        ]

        // REST
        case (.rest, .en): pool = [
            "Nice. Don’t get too comfy",
            "Breathe. Next round soon",
            "You’re earning this rest",
            "Shake it out, stay ready",
            "Heart’s working, good"
        ]
        case (.rest, .ru): pool = [
            "Норм, только не расслабляйся",
            "Дыши. Скоро следующий раунд",
            "Ты заслужил эту паузу",
            "Встряхнись, будь наготове",
            "Сердце пашет — это хорошо"
        ]
        case (.rest, .uk): pool = [
            "Норм, тільки не розслабляйся",
            "Дихай. Скоро наступний раунд",
            "Ти заслужив цю паузу",
            "Струснись, будь напоготові",
            "Серце працює — і це добре"
        ]
        case (.rest, .es): pool = [
            "Bien. No te acomodes",
            "Respira. Próxima ronda pronto",
            "Te ganaste este descanso",
            "Sacúdete, mantente listo",
            "El corazón trabaja, bien"
        ]

        // REST BETWEEN SETS
        case (.restBetweenSets, .en): pool = [
            "New set, new you",
            "You survived that. Impressive",
            "Half human, half engine",
            "Water. Now.",
            "Check posture, not Instagram"
        ]
        case (.restBetweenSets, .ru): pool = [
            "Новый сет — новая версия тебя",
            "Это пережил. Уже неплохо",
            "Наполовину человек, наполовину двигатель",
            "Вода. Сейчас.",
            "Проверь осанку, а не Инстаграм"
        ]
        case (.restBetweenSets, .uk): pool = [
            "Новий сет — нова версія тебе",
            "Це пережив. Вже непогано",
            "Наполовину людина, наполовину двигун",
            "Вода. Зараз.",
            "Перевір поставу, а не Instagram"
        ]
        case (.restBetweenSets, .es): pool = [
            "Nuevo set, nuevo tú",
            "Sobreviviste a eso. Impresionante",
            "Mitad humano, mitad motor",
            "Agua. Ahora.",
            "Revisa la postura, no Instagram"
        ]

        // FINISHED
        case (.finished, .en): pool = [
            "Session complete. Still alive?",
            "Save this. Repeat later",
            "Future you says thanks",
            "Screenshot this victory"
        ]
        case (.finished, .ru): pool = [
            "Сессия закончена. Всё ещё жив?",
            "Запомни это. Повтори позже",
            "Будущий ты говорит спасибо",
            "Зафиксируй победу скриншотом"
        ]
        case (.finished, .uk): pool = [
            "Сесію завершено. Ще живий?",
            "Запам’ятай це. Повтори пізніше",
            "Майбутній ти каже «дякую»",
            "Зафіксуй перемогу скріном"
        ]
        case (.finished, .es): pool = [
            "Sesión completa. ¿Sigues vivo?",
            "Guárdalo. Repite luego",
            "Tu yo del futuro dice gracias",
            "Captura esta victoria"
        ]

        default:
            pool = []
        }

        return pool.randomElement()
    }
}

// MARK: - ActiveTimerView — Main training screen / Экран активной тренировки
struct ActiveTimerView: View {

    @Environment(\.isRunningUnitTests) private var isRunningUnitTests
    @StateObject private var viewModel: ActiveTimerViewModel

    // MARK: Visual state / Визуальное состояние
    @State private var phasePulse: Bool = false
    @State private var ringPulse: Bool = false
    @State private var settings: AppSettings = .default

    // MARK: Floating phrase state / Состояние всплывающей фразы
    @State private var phraseText: String?
    @State private var showPhrase: Bool = false
    @State private var phrasePulse: Bool = false

    // MARK: Timer state flags / Флаги состояния таймера
    @State private var hasStarted: Bool = false
    @State private var isPaused: Bool = false

    // MARK: Layout constants / Константы лейаута
    private let ringDiameter: CGFloat = 240
    private var countdownFontSize: CGFloat { ringDiameter * 0.8 }

    // MARK: Init
    /// Inject shared ActiveTimerViewModel (single source of truth).
    /// Внедряем общую ActiveTimerViewModel (единый источник правды).
    init(viewModel: ActiveTimerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                                setCycleLabel
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

                        setCycleLabel
                            .padding(.top, 4)

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
                                if viewModel.state.currentPhase == .prepare {
                                    showPhasePhrase(for: .prepare)
                                } else {
                                    showPhasePhrase(for: viewModel.state.currentPhase)
                                }
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
                guard hasStarted else { return }
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
                        showPhasePhrase(for: viewModel.state.currentPhase)
                    } else {
                        hidePhrase()
                    }
                    viewModel.start()
                }
            }

            // При смене ориентации на ландшафтную — скрыть фразу
            .onChange(of: isLandscape) { nowLandscape in
                if nowLandscape {
                    hidePhrase()
                }
            }
        }
        .background(Color.theme(.bgPrimary))
        .navigationTitle("Training")
        .navigationBarTitleDisplayMode(.inline)

        .task {
            guard !isRunningUnitTests else { return }
            if let loaded = try? await SettingsStore().load() {
                settings = loaded
            } else {
                settings = .default
            }
            applyIdleTimerPolicy()
        }

        .onChange(of: settings.keepScreenAwake) { _ in
            applyIdleTimerPolicy()
        }

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
        let lang = resolveLanguage()
        phraseText = PhraseRepository.randomPhrase(for: phase, lang: lang)
        withAnimation {
            showPhrase = phraseText != nil
        }
        phrasePulse = false
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
        if !hasStarted {
            return .idle
        }
        if isPaused {
            return .paused
        }
        if viewModel.state.remainingTime > 0 && viewModel.state.progress > 0 {
            return .running
        }
        return .idle
    }

    private func handleRingPulseForCountdown(_ remaining: Int) {
        guard (1...3).contains(remaining) else { return }
        ringPulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            ringPulse = false
        }
    }

    private func applyIdleTimerPolicy() {
        guard !isRunningUnitTests else { return }
        UIApplication.shared.isIdleTimerDisabled = settings.keepScreenAwake
    }
}

// MARK: - Preview / Превью
struct ActiveTimerView_Previews: PreviewProvider {
    static var previews: some View {
        let engine = TimerEngine()
        let vm = ActiveTimerViewModel(config: .default, engine: engine)
        return Group {
            NavigationStack {
                ActiveTimerView(viewModel: vm)
            }
            .previewDisplayName("Portrait")

            NavigationStack {
                ActiveTimerView(viewModel: vm)
            }
            .previewInterfaceOrientation(.landscapeLeft)
            .previewDisplayName("Landscape")
        }
    }
}

