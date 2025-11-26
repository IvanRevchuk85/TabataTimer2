//
//  HapticsServiceProtocol.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import Foundation

// MARK: - HapticsServiceProtocol — Протокол хаптик‑сервиса
/// Abstraction for triggering haptics on supported devices.
/// Абстракция для вызова хаптики на поддерживаемых устройствах.
protocol HapticsServiceProtocol: AnyObject {

    // MARK: Phase change — Смена фазы
    /// Trigger haptic for phase change.
    /// Вызвать хаптику при смене фазы.
    func phaseChanged()

    // MARK: Countdown tick — Обратный отсчёт
    /// Trigger haptic for countdown tick (3…2…1).
    /// Вызвать хаптику для обратного отсчёта (3…2…1).
    func countdownTick()

    // MARK: Completion — Завершение
    /// Trigger haptic for session completion.
    /// Вызвать хаптику при завершении сессии.
    func completed()
}

