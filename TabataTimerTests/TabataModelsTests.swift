//
//  TabataModelsTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 24.11.2025.
//

import XCTest
@testable import TabataTimer

// MARK: - TabataModelsTests — Тесты доменных моделей Табата
/// Unit tests for Tabata domain models (Config/Plan/Interval/Phase).
/// Юнит‑тесты для доменных моделей Табата (Конфиг/План/Интервал/Фаза).
final class TabataModelsTests: XCTestCase {

    // MARK: - Basic generation with default config — Базовая генерация с дефолтной конфигурацией
    func testPlanGeneration_DefaultConfig() {
        // given — предусловия
        let config = TabataConfig.default

        // when — действие
        let plan = TabataPlan.build(from: config)

        // then — проверки
        // Plan should not be empty — План не должен быть пустым
        XCTAssertFalse(plan.isEmpty, "Plan should not be empty — План не должен быть пустым")
        // Plan must end with .finished — План должен заканчиваться .finished
        XCTAssertEqual(plan.last?.phase, .finished, "Last phase must be .finished — Последняя фаза должна быть .finished")

        // First phase is .prepare when prepare > 0 — Первая фаза .prepare, если prepare > 0
        if config.prepare > 0 {
            XCTAssertEqual(plan.first?.phase, .prepare, "First phase must be .prepare when prepare > 0 — Первая фаза должна быть .prepare при prepare > 0")
        }

        // Total duration from plan equals formula — Суммарная длительность плана равна формуле
        let computed = TabataPlan.duration(of: plan)
        XCTAssertEqual(computed, config.totalDuration(), "Total duration mismatch — Суммарная длительность не совпадает с totalDuration()")

        // Number of work intervals equals total cycles — Кол-во work-интервалов равно общему числу циклов
        let workCount = plan.filter { $0.phase == .work }.count
        XCTAssertEqual(workCount, config.totalCycles, "Work count must equal total cycles — Кол-во work должно равняться общему числу циклов")

        // Set indices must be within bounds — Индексы сетов должны быть в допустимых пределах
        for interval in plan where interval.phase != .finished {
            XCTAssertTrue(
                interval.setIndex >= 0 && interval.setIndex < config.sets,
                "setIndex out of bounds — setIndex вне диапазона"
            )
        }

        // Rest must not appear after the last cycle in a set — Rest не должен появляться после последнего цикла в сете
        // Проверяем последовательности внутри каждого сета на предмет rest после последнего цикла
        var lastCycleIndexBySet: [Int: Int] = [:]
        for s in 0..<config.sets { lastCycleIndexBySet[s] = config.cyclesPerSet - 1 }
        for interval in plan where interval.phase == .rest {
            let set = interval.setIndex
            let cycle = interval.cycleIndex
            if let lastCycle = lastCycleIndexBySet[set] {
                XCTAssertLessThan(cycle, lastCycle, "rest must not be after the last cycle in set — rest не должен идти после последнего цикла в сете")
            }
        }
    }

    // MARK: - Edge cases: no prepare and no restBetweenSets — Краевые случаи: без подготовки и без отдыха между сетами
    func testPlanGeneration_NoPrepare_NoRestBetweenSets() {
        // given — предусловия
        let config = TabataConfig(
            prepare: 0,
            work: 5,
            rest: 2,
            cyclesPerSet: 2,
            sets: 2,
            restBetweenSets: 0
        )

        // when — действие
        let plan = TabataPlan.build(from: config)

        // then — проверки
        // No .prepare when prepare = 0 — Нет .prepare при prepare = 0
        XCTAssertFalse(plan.contains { $0.phase == .prepare }, "No prepare expected — Не должно быть prepare при prepare = 0")
        // No .restBetweenSets when restBetweenSets = 0 — Нет .restBetweenSets при restBetweenSets = 0
        XCTAssertFalse(plan.contains { $0.phase == .restBetweenSets }, "No restBetweenSets expected — Не должно быть restBetweenSets при restBetweenSets = 0")

        // Total duration equals formula — Суммарная длительность равна формуле
        let computed = TabataPlan.duration(of: plan)
        XCTAssertEqual(computed, config.totalDuration(), "Total duration mismatch — Суммарная длительность не совпадает с totalDuration()")
    }

    // MARK: - Edge case: single set and single cycle — Краевой случай: один сет и один цикл
    func testPlanGeneration_SingleSetSingleCycle() {
        // given — предусловия
        let config = TabataConfig(
            prepare: 3,
            work: 5,
            rest: 2,
            cyclesPerSet: 1,
            sets: 1,
            restBetweenSets: 10
        )

        // when — действие
        let plan = TabataPlan.build(from: config)

        // then — проверки
        // Expected phases: prepare -> work -> finished — Ожидаемые фазы: prepare -> work -> finished
        let phases = plan.map { $0.phase }
        XCTAssertEqual(phases, [.prepare, .work, .finished], "Unexpected phase sequence — Неверная последовательность фаз")

        // Ensure no rest or restBetweenSets in single set/single cycle — Отсутствие rest и restBetweenSets
        XCTAssertFalse(plan.contains { $0.phase == .rest }, "No rest expected for single cycle — Не должно быть rest при одном цикле")
        XCTAssertFalse(plan.contains { $0.phase == .restBetweenSets }, "No restBetweenSets expected for single set — Не должно быть restBetweenSets при одном сете")

        // Total duration equals formula — Суммарная длительность равна формуле
        let computed = TabataPlan.duration(of: plan)
        XCTAssertEqual(computed, config.totalDuration(), "Total duration mismatch — Суммарная длительность не совпадает с totalDuration()")
    }

    // MARK: - Cycle indices inside sets — Проверка индексов циклов внутри сетов
    func testCycleIndicesWithinSets() {
        // given — предусловия
        let config = TabataConfig(
            prepare: 2,
            work: 4,
            rest: 2,
            cyclesPerSet: 3,
            sets: 2,
            restBetweenSets: 5
        )

        // when — действие
        let plan = TabataPlan.build(from: config)

        // then — проверки
        // For each set: work intervals should have cycleIndex in 0..<(cyclesPerSet)
        // Для каждого сета: у work cycleIndex должен быть в 0..<(cyclesPerSet)
        var setToCycleCounts: [Int: Int] = [:]
        for interval in plan {
            switch interval.phase {
            case .work:
                XCTAssertTrue(
                    (0..<config.cyclesPerSet).contains(interval.cycleIndex),
                    "work.cycleIndex out of range — cycleIndex для work вне диапазона"
                )
                setToCycleCounts[interval.setIndex, default: 0] += 1

            case .rest:
                // Rest between cycles only exists when cyclesPerSet > 1
                // Rest между циклами существует только если cyclesPerSet > 1
                if config.cyclesPerSet > 1 {
                    let upper = config.cyclesPerSet - 1
                    XCTAssertTrue(
                        (0..<upper).contains(interval.cycleIndex),
                        "rest.cycleIndex out of range — cycleIndex для rest вне диапазона"
                    )
                } else {
                    // If cyclesPerSet == 1, there must be no rest intervals at all
                    // Если cyclesPerSet == 1, rest‑интервалов быть не должно
                    XCTFail("Unexpected rest interval when cyclesPerSet == 1 — Неожиданный rest при cyclesPerSet == 1")
                }

            case .prepare, .restBetweenSets, .finished:
                XCTAssertEqual(
                    interval.cycleIndex, -1,
                    "Non-cycle phases must have cycleIndex = -1 — У фаз вне цикла cycleIndex должен быть -1"
                )
            }
        }

        // Each set must contain exactly cyclesPerSet work intervals
        // В каждом сете должно быть ровно cyclesPerSet work‑интервалов
        for set in 0..<config.sets {
            XCTAssertEqual(
                setToCycleCounts[set], config.cyclesPerSet,
                "Unexpected work count in set — Некорректное число work в сете"
            )
        }

        // Ensure no rest after last cycle in each set — Проверяем отсутствие rest после последнего цикла
        for set in 0..<config.sets {
            let lastCycle = config.cyclesPerSet - 1
            let hasRestAfterLastCycle = plan.contains { $0.phase == .rest && $0.setIndex == set && $0.cycleIndex == lastCycle }
            XCTAssertFalse(hasRestAfterLastCycle, "rest must not follow the last cycle in set — rest не должен идти после последнего цикла в сете")
        }
    }

    // MARK: - orderIndex monotonicity — Монотонность orderIndex
    func testOrderIndexMonotonicity() {
        // given — предусловия
        let config = TabataConfig.default

        // when — действие
        let plan = TabataPlan.build(from: config)

        // then — проверки
        // orderIndex must strictly increase from 0..<(count)
        // orderIndex должен возрастать от 0 до count-1
        let orderIndices = plan.map { $0.orderIndex }
        let sorted = orderIndices.sorted()
        XCTAssertEqual(orderIndices, sorted, "orderIndex must be strictly increasing — orderIndex должен монотонно возрастать")
        XCTAssertEqual(orderIndices.first, 0, "First orderIndex must be 0 — Первый orderIndex должен быть 0")
        XCTAssertEqual(orderIndices.last, orderIndices.count - 1, "Last orderIndex must be count-1 — Последний orderIndex должен быть count - 1")
    }
}
