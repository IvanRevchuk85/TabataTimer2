//
//  SamplePlans.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 29.11.2025.
//
//  MARK: Overview — Обзор
//  Small helpers to build deterministic Tabata plans for tests.
//  Небольшие хелперы для построения детерминированных планов Табата для тестов.
//

import Foundation
@testable import TabataTimer

// MARK: - SamplePlans — Helpers / Хелперы
enum SamplePlans {

    // MARK: Simple linear plan — Простой линейный план
    /// Simple plan with short, easy-to-reason durations:
    /// prepare(3) → work(5) → rest(2) → work(5) → finished(0)
    /// Упрощённый план с понятными длительностями:
    /// prepare(3) → work(5) → rest(2) → work(5) → finished(0)
    static func simplePlan() -> [TabataInterval] {
        var order = 0
        let prepare = TabataInterval(phase: .prepare, duration: 3, setIndex: 0, cycleIndex: -1, orderIndex: order); order += 1
        let work1   = TabataInterval(phase: .work, duration: 5, setIndex: 0, cycleIndex: 0,  orderIndex: order); order += 1
        let rest    = TabataInterval(phase: .rest, duration: 2, setIndex: 0, cycleIndex: 0,  orderIndex: order); order += 1
        let work2   = TabataInterval(phase: .work, duration: 5, setIndex: 0, cycleIndex: 1,  orderIndex: order); order += 1
        let finish  = TabataInterval(phase: .finished, duration: 0, setIndex: 0, cycleIndex: -1, orderIndex: order)
        return [prepare, work1, rest, work2, finish]
    }

    // MARK: From config — Из конфига
    /// Build a plan from provided config via TabataPlan.
    /// Построить план из заданного конфига через TabataPlan.
    static func plan(from config: TabataConfig) -> [TabataInterval] {
        TabataPlan.build(from: config)
    }

    // MARK: Default config sample — Образец с дефолтным конфигом
    /// Default-config plan (as in the app), useful for smoke tests.
    /// План по конфигу по умолчанию (как в приложении), полезно для smoke‑тестов.
    static func defaultPlan() -> [TabataInterval] {
        TabataPlan.build(from: .default)
    }
}
