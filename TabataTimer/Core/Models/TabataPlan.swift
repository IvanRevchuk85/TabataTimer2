//
//  TabataPlan.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 22.11.2025.
//

import Foundation

// MARK: - Генератор плана тренировки
/// Строит линейную последовательность интервалов на основе конфигурации.
/// Порядок:
/// 1) prepare (если > 0)
/// 2) Для каждого сета:
///    - Для каждого цикла: work (+ rest, если это не последний цикл в сете)
///    - После сета: restBetweenSets (если это не последний сет и длительность > 0)
/// 3) finished (нулевой интервал для удобства обработки завершения)
enum TabataPlan {

    // MARK: - Построение плана
    static func build(from config: TabataConfig) -> [TabataInterval] {
        var result: [TabataInterval] = []
        var order = 0

        // 1) Prepare
        if config.prepare > 0 {
            result.append(
                TabataInterval(
                    phase: .prepare,
                    duration: config.prepare,
                    setIndex: 0,
                    cycleIndex: -1,
                    orderIndex: order
                )
            )
            order += 1
        }

        // 2) Sets and cycles
        for set in 0..<config.sets {
            for cycle in 0..<config.cyclesPerSet {
                // Work
                result.append(
                    TabataInterval(
                        phase: .work,
                        duration: config.work,
                        setIndex: set,
                        cycleIndex: cycle,
                        orderIndex: order
                    )
                )
                order += 1

                // Rest (между циклами, кроме последнего цикла в сете)
                let isLastCycleInSet = (cycle == config.cyclesPerSet - 1)
                if !isLastCycleInSet, config.rest > 0 {
                    result.append(
                        TabataInterval(
                            phase: .rest,
                            duration: config.rest,
                            setIndex: set,
                            cycleIndex: cycle,
                            orderIndex: order
                        )
                    )
                    order += 1
                }
            }

            // Rest between sets (между сетами, кроме последнего сета)
            let isLastSet = (set == config.sets - 1)
            if !isLastSet, config.restBetweenSets > 0 {
                result.append(
                    TabataInterval(
                        phase: .restBetweenSets,
                        duration: config.restBetweenSets,
                        setIndex: set,
                        cycleIndex: -1,
                        orderIndex: order
                    )
                )
                order += 1
            }
        }

        // 3) Finished (нулевой интервал для унификации завершения)
        result.append(
            TabataInterval(
                phase: .finished,
                duration: 0,
                setIndex: config.sets - 1,
                cycleIndex: -1,
                orderIndex: order
            )
        )

        return result
    }

    // MARK: - Вспомогательные методы
    /// Подсчет суммарной длительности на основе сгенерированного плана
    /// (исключая финальный .finished).
    static func duration(of plan: [TabataInterval]) -> Int {
        plan.reduce(0) { partial, interval in
            partial + (interval.phase == .finished ? 0 : interval.duration)
        }
    }
}
