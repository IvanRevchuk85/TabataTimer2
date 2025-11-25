//
//  TimerEngine.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 25.11.2025.
//

import Foundation

// MARK: - TimerEngine — Движок таймера (actor)
// Actor-based engine to safely drive the Tabata plan with async ticks.
// Реализация движка на actor для потокобезопасного исполнения плана с асинхронными тиками.
actor TimerEngine: TimerEngineProtocol {

    // MARK: State — Состояние
    /// Current high-level state of the engine.
    /// Текущее высокоуровневое состояние движка.
    private(set) var state: TimerState = .idle

    // MARK: Plan & position — План и позиция
    /// Planned sequence of intervals.
    /// Предрассчитанный план интервалов.
    private var plan: [TabataInterval] = []

    /// Index of the current interval in the plan.
    /// Индекс текущего интервала в плане.
    private var currentIndex: Int = 0

    /// Remaining seconds in the current interval.
    /// Оставшиеся секунды в текущем интервале.
    private var remainingSeconds: Int = 0

    // MARK: Task & stream — Задача и поток событий
    /// Background task that produces ticks.
    /// Фоновая задача, которая эмитит тики.
    private var tickTask: Task<Void, Never>?

    /// Stream of timer events for observers.
    /// Поток событий таймера для подписчиков.
    private var stream: AsyncStream<TimerEvent>

    /// Continuation used to push events into the stream.
    /// Continuation, через который мы пушим события в поток.
    private var continuation: AsyncStream<TimerEvent>.Continuation

    /// Public read-only access to events stream.
    /// Публичный доступ только для чтения к потоку событий.
    var events: AsyncStream<TimerEvent> { stream }

    // MARK: - Init — Инициализация
    init() {
        // Initialize stream/continuation via a local variable, then assign to actor properties.
        // Инициализируем stream/continuation через локальную переменную, затем сохраняем в свойства актора.
        var cont: AsyncStream<TimerEvent>.Continuation!
        let s = AsyncStream<TimerEvent> { c in
            cont = c
        }
        self.stream = s
        self.continuation = cont
    }

    // MARK: - Configuration — Конфигурация
    /// Configure engine with a prebuilt plan and reset internal state.
    /// Сконфигурировать движок предрассчитанным планом и сбросить внутреннее состояние.
    func configure(with plan: [TabataInterval]) {
        cancelTickTaskIfNeeded()
        self.plan = plan
        self.currentIndex = 0
        self.remainingSeconds = plan.first?.duration ?? 0
        self.state = .idle

        // Recreate the stream so previous subscribers don't interfere with a new session.
        // Пересоздаём поток, чтобы прошлые подписчики не мешали новой сессии.
        recreateStream()
    }

    // MARK: - Control — Управление
    /// Start counting down from the current interval.
    /// Запустить отсчёт с текущего интервала.
    func start() {
        guard !plan.isEmpty else { return }
        guard state == .idle || state == .paused else { return }

        if state == .idle {
            // Safely clamp index.
            // Безопасно ограничиваем индекс.
            currentIndex = min(max(currentIndex, 0), plan.count - 1)
            remainingSeconds = plan[currentIndex].duration

            // Emit initial phase change for UI sync.
            // Эмитим начальное событие смены фазы для синхронизации UI.
            let interval = plan[currentIndex]
            continuation.yield(.phaseChanged(phase: interval.phase, index: currentIndex))
        }

        state = .running
        startTicking()
    }

    /// Pause the countdown, preserving remaining time.
    /// Поставить на паузу, сохранив оставшееся время.
    func pause() {
        guard state == .running else { return }
        cancelTickTaskIfNeeded()
        state = .paused
    }

    /// Resume countdown after a pause.
    /// Возобновить отсчёт после паузы.
    func resume() {
        guard state == .paused else { return }
        state = .running

        // Emit an immediate tick to notify observers right away after resume.
        // Эмитим немедленный тик, чтобы подписчики сразу получили обновление после resume.
        continuation.yield(.tick(remaining: remainingSeconds))

        startTicking()
    }

    /// Reset engine to idle and clear progress.
    /// Сбросить движок в idle и очистить прогресс.
    func reset() {
        cancelTickTaskIfNeeded()
        currentIndex = 0
        remainingSeconds = plan.first?.duration ?? 0
        state = .idle

        // Open a new stream for a new session.
        // Открываем новый поток для новой сессии.
        recreateStream()
    }

    // MARK: - Internal ticking — Внутренний цикл тиков
    /// Create and run ticking task.
    /// Создать и запустить задачу тиков.
    private func startTicking() {
        cancelTickTaskIfNeeded()

        // Start a Task; all state interactions occur inside the actor via await runTickLoop().
        // Запускаем Task, но всё взаимодействие со стейтом происходит внутри актора через await runTickLoop().
        tickTask = Task { [weak self] in
            guard let self else { return }
            await self.runTickLoop()
        }
    }

    /// Main ticking loop executed inside the actor.
    /// Основной цикл тиков, выполняющийся внутри актора.
    private func runTickLoop() async {
        // If already at the terminal interval — finish immediately.
        // Если уже на финальном интервале — сразу завершаем.
        if isAtFinishedInterval() {
            finish()
            return
        }

        // Ensure remainingSeconds initialized correctly.
        // Гарантируем корректную инициализацию remainingSeconds.
        if remainingSeconds <= 0, !plan.isEmpty {
            remainingSeconds = max(0, plan[currentIndex].duration)
        }

        while !Task.isCancelled {
            // Sleep 1 second between ticks.
            // Спим 1 секунду между тиками.
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            tick()
        }
    }

    /// Handle one logical tick: decrement remaining, emit event, and advance interval if needed.
    /// Обработать один тик: уменьшить время, эмитить событие, при необходимости перейти к следующему интервалу.
    private func tick() {
        guard state == .running else { return }

        if remainingSeconds > 0 {
            remainingSeconds -= 1
            continuation.yield(.tick(remaining: remainingSeconds))
        }

        if remainingSeconds == 0 {
            advanceInterval()
        }
    }

    /// Move to next interval or finish if plan is over.
    /// Перейти к следующему интервалу или завершить сессию, если план закончился.
    private func advanceInterval() {
        currentIndex += 1

        // Out of bounds — finish the session.
        // Вышли за границы плана — завершаем сессию.
        if currentIndex >= plan.count {
            finish()
            return
        }

        let interval = plan[currentIndex]

        // Terminal .finished interval.
        // Терминальный интервал .finished.
        if interval.phase == .finished {
            finish()
            return
        }

        // Setup next interval and emit phase change.
        // Настраиваем следующий интервал и эмитим смену фазы.
        remainingSeconds = interval.duration
        continuation.yield(.phaseChanged(phase: interval.phase, index: currentIndex))
    }

    /// Complete the session: emit completed, set finished, stop ticking.
    /// Завершить сессию: эмитить completed, выставить finished, остановить тики.
    private func finish() {
        cancelTickTaskIfNeeded()
        state = .finished
        continuation.yield(.completed)
        // Intentionally do not close the stream immediately — late subscribers can still get completed.
        // Поток намеренно не закрываем сразу — поздние подписчики всё ещё могут получить completed.
    }

    // MARK: - Helpers — Вспомогательные методы
    /// Check if current interval is terminal "finished" with zero duration.
    /// Проверить, является ли текущий интервал терминальным .finished с нулевой длительностью.
    private func isAtFinishedInterval() -> Bool {
        guard currentIndex < plan.count else { return true }
        let current = plan[currentIndex]
        return current.phase == .finished && current.duration == 0
    }

    /// Cancel current tick task if it exists.
    /// Отменить текущую задачу тиков, если она есть.
    private func cancelTickTaskIfNeeded() {
        tickTask?.cancel()
        tickTask = nil
    }

    /// Recreate AsyncStream and its continuation in an actor-safe way.
    /// Безопасно пересоздать AsyncStream и continuation внутри актора.
    private func recreateStream() {
        // Finish the old continuation (if any).
        // Завершаем старое continuation (если уже было).
        continuation.finish()

        // Create a new stream via a local variable cont.
        // Создаём новый поток через локальную переменную cont.
        var cont: AsyncStream<TimerEvent>.Continuation!
        let newStream = AsyncStream<TimerEvent> { c in
            cont = c
        }

        stream = newStream
        continuation = cont
    }
}

