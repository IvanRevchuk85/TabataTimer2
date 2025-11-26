//
//  ActiveTimerViewModel.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 25.11.2025.
//

import Foundation
import Combine

// MARK: - ActiveTimerViewModel — Модель представления активной тренировки
// ObservableObject ViewModel that bridges Core (engine/plan) to UI.
// ObservableObject ViewModel, связывающий Core (движок/план) с UI.
@MainActor
final class ActiveTimerViewModel: ObservableObject {

    // MARK: Published state — Публикуемое состояние
    /// UI-facing aggregated session state.
    /// Агрегированное состояние для UI.
    @Published private(set) var state: TabataSessionState

    // MARK: Dependencies — Зависимости
    private let engine: TimerEngineProtocol
    private let config: TabataConfig
    private let sound: SoundServiceProtocol
    private let haptics: HapticsServiceProtocol

    // MARK: Plan & position — План и позиция
    private var plan: [TabataInterval] = []
    private var currentIndex: Int = 0
    private var currentPhase: TabataPhase = .prepare
    private var remaining: Int = 0
    private var elapsed: Int = 0
    private var totalDuration: Int = 0

    // MARK: Countdown dedup — Защита от дублей обратного отсчёта
    private var lastAnnouncedCountdown: Int?

    // MARK: Async subscription — Асинхронная подписка
    private var eventsTask: Task<Void, Never>?

    // MARK: - Init — Инициализация
    /// Initialize with config and engine, build plan, configure engine, and subscribe to events.
    /// Инициализируем с конфигом и движком, строим план, конфигурируем движок и подписываемся на события.
    init(
        config: TabataConfig,
        engine: TimerEngineProtocol,
        sound: SoundServiceProtocol = SoundService(),
        haptics: HapticsServiceProtocol = DefaultHapticsService()
    ) {
        self.config = config
        self.engine = engine
        self.sound = sound
        self.haptics = haptics

        // Build plan and initialize derived values.
        // Строим план и инициализируем производные значения.
        self.plan = TabataPlan.build(from: config)
        self.totalDuration = TabataPlan.duration(of: plan)

        // Initial state — idle for UI.
        // Начальное состояние — idle для UI.
        self.state = TabataSessionState.idle(
            totalSets: config.sets,
            totalCyclesPerSet: config.cyclesPerSet,
            totalDuration: totalDuration
        )

        // Configure engine with the computed plan.
        // Конфигурируем движок предрассчитанным планом.
        engine.configure(with: plan)

        // Prepare initial indices/phase.
        // Подготавливаем начальные индексы/фазу.
        self.currentIndex = 0
        self.currentPhase = plan.first?.phase ?? .finished
        self.remaining = plan.first?.duration ?? 0
        self.elapsed = 0
        self.lastAnnouncedCountdown = nil

        // Subscribe to engine events.
        // Подписываемся на события движка.
        subscribeToEngineEvents()
    }

    deinit {
        // Cancel subscription task.
        // Отменяем задачу подписки.
        eventsTask?.cancel()
    }

    // MARK: - Public control — Публичное управление
    /// Start the engine.
    /// Запустить движок.
    func start() {
        engine.start()
    }

    /// Pause the engine.
    /// Поставить на паузу.
    func pause() {
        engine.pause()
    }

    /// Resume the engine.
    /// Возобновить работу.
    func resume() {
        engine.resume()
    }

    /// Reset engine and state to initial idle.
    /// Сбросить движок и состояние к начальному idle.
    func reset() {
        eventsTask?.cancel()
        eventsTask = nil

        engine.reset()
        engine.configure(with: plan)

        currentIndex = 0
        currentPhase = plan.first?.phase ?? .finished
        remaining = plan.first?.duration ?? 0
        elapsed = 0
        lastAnnouncedCountdown = nil

        // Publish idle state again.
        // Публикуем состояние idle заново.
        publishState()

        // Re-subscribe.
        // Переподписываемся.
        subscribeToEngineEvents()
    }

    // MARK: - Build plan — Построение плана
    /// Rebuild plan from config (if needed externally).
    /// Пересобрать план из конфига (если понадобится извне).
    func buildPlan() {
        plan = TabataPlan.build(from: config)
        totalDuration = TabataPlan.duration(of: plan)
        engine.configure(with: plan)

        // Reset derived indexes according to new plan.
        // Сбрасываем производные индексы согласно новому плану.
        currentIndex = 0
        currentPhase = plan.first?.phase ?? .finished
        remaining = plan.first?.duration ?? 0
        elapsed = 0
        lastAnnouncedCountdown = nil
        publishState()
    }

    // MARK: - Subscribe to events — Подписка на события
    /// Subscribe to engine events and map them to TabataSessionState.
    /// Подписываемся на события движка и преобразуем их в TabataSessionState.
    private func subscribeToEngineEvents() {
        // Cancel previous task if any.
        // Отменяем предыдущую задачу, если была.
        eventsTask?.cancel()

        let stream = engine.events

        eventsTask = Task { [weak self] in
            guard let self else { return }
            for await event in stream {
                await self.handle(event)
            }
        }
    }

    // MARK: - Event handling — Обработка событий
    /// Handle one TimerEvent: update local fields and publish new state.
    /// Обрабатываем одно событие TimerEvent: обновляем локальные поля и публикуем новое состояние.
    private func handle(_ event: TimerEvent) async {
        switch event {
        case .phaseChanged(let phase, let index):
            // Update current interval/phase and reset remaining for that interval.
            // Обновляем текущий интервал/фазу и сбрасываем remaining для этого интервала.
            currentIndex = index
            currentPhase = phase
            remaining = plan[safe: index]?.duration ?? 0
            // Do not change elapsed here — it advances on ticks.
            // Здесь elapsed не меняем — он увеличивается на тиках.

            // Triggers: sound + haptics on phase change.
            sound.playPhaseChange()
            haptics.phaseChanged()

            // Reset countdown dedup when phase changes (новая фаза — новый отсчёт).
            lastAnnouncedCountdown = nil

            publishState()

        case .tick(let remainingSeconds):
            // Update remaining and elapsed; clamp elapsed to totalDuration.
            // Обновляем remaining и elapsed; ограничиваем elapsed по totalDuration.
            remaining = max(0, remainingSeconds)
            elapsed = min(totalDuration, elapsed + 1)

            // Triggers: countdown tick at 3,2,1 (deduplicated).
            if (1...3).contains(remaining) {
                if lastAnnouncedCountdown != remaining {
                    sound.playCountdownTick()
                    haptics.countdownTick()
                    lastAnnouncedCountdown = remaining
                }
            } else {
                // Сбрасываем флаг, чтобы следующий заход в 3..2..1 снова отработал.
                lastAnnouncedCountdown = nil
            }

            publishState()

        case .completed:
            // Move to finished phase and finalize progress.
            // Переводим в фазу finished и финализируем прогресс.
            currentPhase = .finished
            remaining = 0
            elapsed = totalDuration
            // Keep currentIndex at last known or set to last interval index if available.
            // Оставляем currentIndex последним известным или ставим последний индекс, если доступен.
            if let lastIndex = plan.indices.last {
                currentIndex = lastIndex
            }

            // Triggers: completion sound + haptics.
            sound.playCompleted()
            haptics.completed()

            // Завершаем цикл обратного отсчёта.
            lastAnnouncedCountdown = nil

            publishState()
        }
    }

    // MARK: - Publish state — Публикация состояния
    /// Compute UI-facing session state and assign to @Published.
    /// Вычисляем состояние для UI и присваиваем в @Published.
    private func publishState() {
        let (uiSet, uiCycle) = uiSetCycle(for: currentIndex)

        let progress = totalDuration > 0
            ? min(1.0, max(0.0, Double(elapsed) / Double(totalDuration)))
            : 0.0

        state = TabataSessionState(
            currentIntervalIndex: currentIndex,
            currentPhase: currentPhase,
            remainingTime: remaining,
            totalDuration: totalDuration,
            elapsedTime: elapsed,
            currentSet: uiSet,
            totalSets: config.sets,
            currentCycle: uiCycle,
            totalCyclesPerSet: config.cyclesPerSet,
            progress: progress
        )
    }

    // MARK: - Helpers — Вспомогательные методы
    /// Compute 1-based set/cycle for UI from a plan index (0 when not applicable).
    /// Вычисляем номера сета/цикла (с 1 для UI) по индексу плана (0, если не применимо).
    private func uiSetCycle(for index: Int) -> (set: Int, cycle: Int) {
        guard let interval = plan[safe: index] else { return (0, 0) }
        let setUI = interval.setIndex >= 0 ? interval.setIndex + 1 : 0
        let cycleUI = interval.cycleIndex >= 0 ? interval.cycleIndex + 1 : 0
        return (setUI, cycleUI)
    }
}

// MARK: - Safe subscript — Безопасный сабскрипт
private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - DefaultHapticsService — Минимальная реализация по умолчанию
/// A minimal default haptics service used when none is injected.
/// Минимальная реализация хаптик‑сервиса по умолчанию, если не инжектирован.
private final class DefaultHapticsService: HapticsServiceProtocol {
    func phaseChanged() { /* no-op in default */ }
    func countdownTick() { /* no-op in default */ }
    func completed() { /* no-op in default */ }
}
