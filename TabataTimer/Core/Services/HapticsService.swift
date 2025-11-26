//
//  HapticsService.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - HapticsService — Реализация хаптик‑сервиса
/// Minimal haptics service:
/// - iOS/tvOS: UINotificationFeedbackGenerator + UIImpactFeedbackGenerator
/// - other platforms: no-op
final class HapticsService: HapticsServiceProtocol {

    #if canImport(UIKit)
    // Предсоздаём генераторы для производительности
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    // Небольшой дебаунс для countdown, чтобы избежать слишком частых срабатываний
    private var lastCountdownTickDate: Date?
    private let countdownDebounce: TimeInterval = 0.08 // ~80мс

    init() {
        // Подготовка генераторов уменьшает задержку при первом срабатывании
        notificationGenerator.prepare()
        impactGenerator.prepare()
    }

    // MARK: Phase change — Смена фазы
    func phaseChanged() {
        notificationGenerator.notificationOccurred(.success)
        // Подготовим генераторы к следующему событию
        notificationGenerator.prepare()
        impactGenerator.prepare()
    }

    // MARK: Countdown tick — Обратный отсчёт
    func countdownTick() {
        let now = Date()
        if let last = lastCountdownTickDate, now.timeIntervalSince(last) < countdownDebounce {
            return
        }
        lastCountdownTickDate = now

        // Более “короткий” тактильный удар
        impactGenerator.impactOccurred(intensity: 0.7)
        impactGenerator.prepare()
    }

    // MARK: Completion — Завершение
    func completed() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    #else
    // MARK: - Non-UIKit platforms — Платформы без UIKit (no-op)
    init() {}

    func phaseChanged() {}
    func countdownTick() {}
    func completed() {}
    #endif
}
