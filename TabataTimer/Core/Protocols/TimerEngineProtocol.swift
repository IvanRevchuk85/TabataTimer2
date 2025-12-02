//
//  TimerEngineProtocol.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 24.11.2025.
//

import Foundation

// MARK: - TimerEngineProtocol — Протокол движка таймера
/// Contract for the timer engine that drives the Tabata session.
/// Контракт для движка таймера, управляющего сессией Табата.
@preconcurrency
protocol TimerEngineProtocol: AnyObject {
    // MARK: State — Состояние
    /// Current high-level state of the engine.
    /// Текущее высокоуровневое состояние движка.
    var state: TimerState { get }

    // MARK: Configuration — Конфигурация
    /// Configure engine with a prebuilt plan of intervals.
    /// Сконфигурировать движок предрассчитанным планом интервалов.
    func configure(with plan: [TabataInterval])

    // MARK: Control — Управление
    /// Start counting from the current interval.
    /// Запустить отсчёт с текущего интервала.
    func start()

    /// Pause the countdown, preserving remaining time.
    /// Поставить на паузу, сохранив оставшееся время.
    func pause()

    /// Resume countdown after a pause.
    /// Возобновить отсчёт после паузы.
    func resume()

    /// Reset to initial idle state.
    /// Сбросить в начальное состояние idle.
    func reset()

    // MARK: Events — События
    /// Asynchronous stream of timer events (ticks/phase changes/completion).
    /// Асинхронный поток событий таймера (тики/смены фаз/завершение).
    var events: AsyncStream<TimerEvent> { get }
}
