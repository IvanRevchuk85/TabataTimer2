//
//  FakeDateProvider.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 29.11.2025.
//
//  MARK: Overview — Обзор
//  A controllable date provider for deterministic tests.
//  Управляемый провайдер времени для детерминированных тестов.
//

import Foundation

// MARK: - FakeDateProvider — Test double / Тестовый двойник
/// Provides a mutable "now" date and helpers to advance time.
/// Предоставляет изменяемое "сейчас" и хелперы для продвижения времени.
final class FakeDateProvider {

    // MARK: State — Состояние
    /// Current "now" value used by tests.
    /// Текущее значение "сейчас", используемое в тестах.
    private(set) var now: Date

    // MARK: - Init — Инициализация
    /// Initialize with a given start date (defaults to 1970-01-01).
    /// Инициализация с заданной датой старта (по умолчанию 1970-01-01).
    init(start: Date = Date(timeIntervalSince1970: 0)) {
        self.now = start
    }

    // MARK: - Control — Управление
    /// Advance current time by a positive interval (seconds).
    /// Продвинуть текущее время на положительный интервал (в секундах).
    func advance(by interval: TimeInterval) {
        now = now.addingTimeInterval(interval)
    }

    /// Returns a closure suitable for injecting as dateProvider: { Date }.
    /// Возвращает замыкание, подходящее для инъекции как dateProvider: { Date }.
    func closure() -> () -> Date {
        { [weak self] in
            guard let self else { return Date(timeIntervalSince1970: 0) }
            return self.now
        }
    }
}
