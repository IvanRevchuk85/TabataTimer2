//
//  ActiveTimerViewModel.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 25.11.2025.
//
//  MARK: Overview — Обзор
//  ViewModel that bridges Core (engine/plan) to SwiftUI. Holds derived UI state,
//  subscribes to engine events, triggers sound/haptics, and supports background reconciliation.
//  ViewModel, связывающий Core (движок/план) со SwiftUI. Хранит производное UI‑состояние,
//  подписывается на события движка, триггерит звук/хаптику и поддерживает пересинхронизацию после фона.
//

import Foundation
import Combine
import UIKit

// MARK: - ActiveTimerViewModel — ViewModel / Модель представления
@MainActor
final class ActiveTimerViewModel: ObservableObject {

    // MARK: Published state — Публикуемое состояние
    /// UI-facing aggregated session state.
    /// Агрегированное состояние для UI.
    @Published private(set) var state: TabataSessionState

    // MARK: Exposed read-only — Публичные свойства (только чтение)
    /// Whether the timer is currently running (best-effort, inferred from events).
    /// Идёт ли таймер сейчас (оценка на основе событий).
    var isRunning: Bool { lastEngineState == .running }

    /// Current linear plan of intervals (read-only).
    /// Текущий линейный план интервалов (только чтение).
    var currentPlan: [TabataInterval] { plan }

    // MARK: Dependencies — Зависимости
    private let engine: TimerEngineProtocol
    private var config: TabataConfig
    private let sound: SoundServiceProtocol
    private let haptics: HapticsServiceProtocol

    /// Settings provider closure to read current app settings when needed.
    /// Провайдер настроек: замыкание, возвращающее актуальные настройки при обращении.
    private let settingsProvider: () -> AppSettings

    // MARK: Plan & position — План и позиция
    private var plan: [TabataInterval] = []
    private var currentIndex: Int = 0
    private var currentPhase: TabataPhase = .prepare
    private var remaining: Int = 0
    private var elapsed: Int = 0
    private var totalDuration: Int = 0

    // MARK: Countdown dedup — Дедупликация обратного отсчёта
    /// Last announced countdown second to avoid duplicates (3, 2, 1).
    /// Последняя озвученная/вибрированная секунда (3, 2, 1), чтобы не дублировать события.
    private var lastAnnouncedCountdown: Int?

    // MARK: Async subscription — Асинхронная подписка
    /// Task that consumes engine events stream.
    /// Задача, потребляющая поток событий движка.
    private var eventsTask: Task<Void, Never>?

    // MARK: App lifecycle observer — Наблюдатель жизненного цикла
    /// Optional observer for auto-pause when app resigns active.
    /// Необязательный наблюдатель для автопаузы при уходе приложения в фон.
    private var lifecycleObserver: AnyObject?
    
    private let shouldConfigureEngine: Bool

    // MARK: Engine state shadow — Теневая копия состояния движка
    /// Best-effort shadow of engine state inferred from events.
    /// Приблизительное состояние движка, выводимое из событий.
    private var lastEngineState: TimerState = .idle

    // MARK: - Init — Инициализация
    /// Initialize with config and engine; build plan, configure engine, subscribe to events.
    /// Инициализация с конфигом и движком; построение плана, конфигурация движка, подписка на события.
    init(
        config: TabataConfig,
        engine: TimerEngineProtocol,
        sound: SoundServiceProtocol = SoundService(),
        haptics: HapticsServiceProtocol = DefaultHapticsService(),
        settingsProvider: @escaping () -> AppSettings = { .default },
        shouldConfigureEngine: Bool = true
    ) {
        self.config = config
        self.engine = engine
        self.sound = sound
        self.haptics = haptics
        self.settingsProvider = settingsProvider
        self.shouldConfigureEngine = shouldConfigureEngine

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

        // Configure engine with the computed plan (optional).
        // Конфигурируем движок предрассчитанным планом (если нужно).
        if shouldConfigureEngine {
            engine.configure(with: plan)
        }

        // Prepare initial indices/phase.
        // Подготавливаем начальные индексы/фазу.
        self.currentIndex = 0
        self.currentPhase = plan.first?.phase ?? .finished
        self.remaining = plan.first?.duration ?? 0
        self.elapsed = 0
        self.lastAnnouncedCountdown = nil
        self.lastEngineState = .idle

        // Subscribe to engine events.
        // Подписываемся на события движка.
        subscribeToEngineEvents()

        // Setup optional auto-pause handling based on settings.
        // Настраиваем опциональную автопаузу на основе настроек.
        setupAutoPauseIfNeeded()
    }

    deinit {
        // Cancel subscription task.
        // Отменяем задачу подписки.
        eventsTask?.cancel()

        // Remove lifecycle observer if any.
        // Удаляем наблюдателя жизненного цикла, если был.
        if let observer = lifecycleObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public control — Публичное управление
    /// Start the engine.
    /// Запустить движок.
    func start() {
        lastEngineState = .running
        engine.start()
    }

    /// Pause the engine.
    /// Поставить на паузу.
    func pause() {
        lastEngineState = .paused
        engine.pause()
    }

    /// Resume the engine after pause.
    /// Возобновить работу после паузы.
    func resume() {
        lastEngineState = .running
        engine.resume()
    }

    /// Reset engine and state to initial idle.
    /// Сбросить движок и состояние к начальному idle.
    func reset() {
        // Stop current subscription and reconfigure engine.
        // Останавливаем текущую подписку и переконфигурируем движок.
        eventsTask?.cancel()
        eventsTask = nil

        engine.reset()
        engine.configure(with: plan)

        // Reset derived fields.
        // Сбрасываем производные поля.
        currentIndex = 0
        currentPhase = plan.first?.phase ?? .finished
        remaining = plan.first?.duration ?? 0
        elapsed = 0
        lastAnnouncedCountdown = nil
        lastEngineState = .idle

        // Resubscribe BEFORE publishing idle to avoid missing early events.
        // Переподписываемся ДО публикации idle, чтобы не пропустить ранние события.
        subscribeToEngineEvents()

        // Publish idle state again.
        // Публикуем состояние idle заново.
        publishState()
    }

    // MARK: - Apply new configuration — Применение новой конфигурации (для общего движка)
    /// Apply a new Tabata configuration to the shared engine safely.
    /// Безопасно применить новую конфигурацию к общему движку.
    /// Используется, чтобы один общий движок обслуживал разные пресеты без конфликтов.
    func applyConfig(_ newConfig: TabataConfig, autoStart: Bool = false) {
        // 1) Если движок не в idle — сбросить в idle, чтобы не было гонок.
        //    Используем state из протокола как источник истины.
        if !engine.state.isIdle {
            reset()
        }

        // 2) Обновить локальную конфигурацию.
        config = newConfig

        // 3) Пересобрать план и длительность.
        plan = TabataPlan.build(from: config)
        totalDuration = TabataPlan.duration(of: plan)

        // 4) Сбросить локальные поля и опубликовать idle.
        currentIndex = 0
        currentPhase = plan.first?.phase ?? .finished
        remaining = plan.first?.duration ?? 0
        elapsed = 0
        lastAnnouncedCountdown = nil
        lastEngineState = .idle

        // 5) Сконфигурировать движок новым планом.
        engine.configure(with: plan)

        // 6) Переподписаться на события (на случай, если движок пересоздал поток).
        subscribeToEngineEvents()

        // 7) Опубликовать idle.
        publishState()

        // 8) Автостарт при необходимости.
        if autoStart {
            start()
        }
    }

    // MARK: - Plan rebuild — Пересборка плана
    /// Rebuild plan from config (if needed externally) and reconfigure engine.
    /// Пересобрать план из конфига (если нужно извне) и переконфигурировать движок.
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
        lastEngineState = .idle

        publishState()
    }

    // MARK: - Events subscription — Подписка на события
    /// Subscribe to engine events and map them to TabataSessionState.
    /// Подписываемся на события движка и преобразуем их в TabataSessionState.
    private func subscribeToEngineEvents() {
        // Cancel previous task if any.
        // Отменяем предыдущую задачу, если была.
        eventsTask?.cancel()

        let stream = engine.events

        eventsTask = Task { [weak self] in
            guard let self else { return }
            // Let the task start before first events arrive.
            // Дадим задаче стартовать до прихода первых событий.
            await Task.yield()
            for await event in stream {
                await self.handle(event)
            }
        }
    }

    // MARK: - Event handling — Обработка событий
    /// Handle one TimerEvent: update local fields and publish new state.
    /// Обработать одно событие TimerEvent: обновить локальные поля и опубликовать новое состояние.
    private func handle(_ event: TimerEvent) async {
        let settings = settingsProvider()

        switch event {
        case .phaseChanged(let phase, let index):
            // Update current interval/phase and reset remaining for that interval.
            // Обновляем текущий интервал/фазу и сбрасываем remaining для этого интервала.
            currentIndex = index
            currentPhase = phase
            remaining = plan[safe: index]?.duration ?? 0
            // elapsed не меняем — он увеличивается на тиках.
            // Do not change elapsed here — it advances on ticks.

            // Triggers: sound + haptics on phase change (respect settings).
            // Триггеры: звук и хаптика при смене фазы (с учётом настроек).
            if settings.isSoundEnabled { sound.playPhaseChange() }
            if settings.isHapticsEnabled { haptics.phaseChanged() }

            // Reset countdown dedup (new phase — new countdown).
            // Сбрасываем защиту от дублей (новая фаза — новый отсчёт).
            lastAnnouncedCountdown = nil

            // Infer engine state as running on phase change.
            // По событию смены фазы считаем, что движок работает.
            lastEngineState = .running

            publishState()

        case .tick(let remainingSeconds):
            // Update remaining and elapsed; clamp elapsed to totalDuration.
            // Обновляем remaining и elapsed; ограничиваем elapsed по totalDuration.
            remaining = max(0, remainingSeconds)
            elapsed = min(totalDuration, elapsed + 1)

            // Triggers: countdown tick at 3,2,1 (deduplicated; respect settings).
            // Триггеры: обратный отсчёт 3,2,1 (без дублей; с учётом настроек).
            if (1...3).contains(remaining) {
                if lastAnnouncedCountdown != remaining {
                    if settings.isSoundEnabled { sound.playCountdownTick() }
                    if settings.isHapticsEnabled { haptics.countdownTick() }
                    lastAnnouncedCountdown = remaining
                }
            } else {
                // Reset dedup so the next 3..2..1 works again.
                // Сбрасываем флаг, чтобы следующий заход 3..2..1 снова отработал.
                lastAnnouncedCountdown = nil
            }

            // Infer engine state as running on tick.
            // По событию тика считаем, что движок работает.
            lastEngineState = .running

            publishState()

        case .completed:
            // Move to finished phase and finalize progress.
            // Переводим в фазу finished и финализируем прогресс.
            currentPhase = .finished
            remaining = 0
            elapsed = totalDuration
            if let lastIndex = plan.indices.last {
                currentIndex = lastIndex
            }

            // Triggers: completion sound + haptics (respect settings).
            // Триггеры: звук и хаптика завершения (с учётом настроек).
            if settings.isSoundEnabled { sound.playCompleted() }
            if settings.isHapticsEnabled { haptics.completed() }

            // End countdown cycle.
            // Завершаем цикл обратного отсчёта.
            lastAnnouncedCountdown = nil

            // Reflect engine finished.
            // Отражаем завершение движка.
            lastEngineState = .finished

            publishState()
        }
    }

    // MARK: - Publish state — Публикация состояния
    /// Compute UI-facing session state and assign to @Published.
    /// Вычислить состояние для UI и присвоить в @Published.
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

    // MARK: - Reconcile (background return) — Пересинхронизация после фона
    /// Apply a new position computed by the background coordinator.
    /// Применить новую позицию, рассчитанную координатором фона.
    func reconcilePosition(newIndex: Int, newRemaining: Int, finished: Bool) {
        // Safety clamps — Страховки
        let clampedIndex = min(max(0, newIndex), plan.count - 1)
        let clampedRemaining = max(0, newRemaining)

        if finished {
            // Finalize local state as completed.
            // Финализируем локальное состояние как завершённое.
            currentIndex = clampedIndex
            currentPhase = .finished
            remaining = 0
            elapsed = totalDuration
            lastAnnouncedCountdown = nil
            lastEngineState = .finished
            publishState()
            return
        }

        // Recompute local fields according to the plan.
        // Пересчитываем локальные поля согласно плану.
        currentIndex = clampedIndex
        currentPhase = plan[safe: clampedIndex]?.phase ?? .finished
        remaining = clampedRemaining

        // elapsed = sum(durations before index) + (currentDuration - remaining).
        // elapsed = сумма длительностей до индекса + (длительность текущего − remaining).
        let elapsedBefore = plan.prefix(clampedIndex).reduce(0) { $0 + ($1.phase == .finished ? 0 : $1.duration) }
        let currentDuration = plan[safe: clampedIndex]?.duration ?? 0
        elapsed = min(totalDuration, elapsedBefore + max(0, currentDuration - clampedRemaining))

        // Reset countdown dedup.
        // Сбрасываем защиту от дублей обратного отсчёта.
        lastAnnouncedCountdown = nil

        // Consider engine running if there is remaining time and not finished.
        // Считаем движок “running”, если осталось время и не завершено.
        lastEngineState = (currentPhase == .finished || remaining == 0) ? .finished : .running

        publishState()
    }

    // MARK: - Helpers — Вспомогательные методы
    /// Compute 1-based set/cycle for UI from a plan index (0 when not applicable).
    /// Вычислить номера сета/цикла (с 1 для UI) по индексу плана (0, если не применимо).
    private func uiSetCycle(for index: Int) -> (set: Int, cycle: Int) {
        guard let interval = plan[safe: index] else { return (0, 0) }
        let setUI = interval.setIndex >= 0 ? interval.setIndex + 1 : 0
        let cycleUI = interval.cycleIndex >= 0 ? interval.cycleIndex + 1 : 0
        return (setUI, cycleUI)
    }

    // MARK: - Auto-pause setup — Настройка автопаузы
    /// Setup auto-pause if enabled in settings (iOS only).
    /// Настроить автопаузу при уходе приложения в фон (только iOS), если включено в настройках.
    private func setupAutoPauseIfNeeded() {
        let settings = settingsProvider()
        guard settings.isAutoPauseEnabled else { return }

        lifecycleObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.engine.pause()
        }
    }
}

// MARK: - Safe subscript — Безопасный сабскрипт
private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - DefaultHapticsService — Реализация по умолчанию
/// A minimal default haptics service used when none is injected.
/// Минимальная реализация хаптик‑сервиса по умолчанию, если не инжектирован.
private final class DefaultHapticsService: HapticsServiceProtocol {
    func phaseChanged() { /* no-op */ }
    func countdownTick() { /* no-op */ }
    func completed() { /* no-op */ }
}
