//
//  TabataSessionStateTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 29.11.2025.
//

import Foundation
import Testing
@testable import TabataTimer

// MARK: - TabataSessionStateTests — Тесты состояния сессии
@Suite("TabataSessionState tests — Тесты состояния сессии")
struct TabataSessionStateTests {

    // MARK: Idle factory
    @Test("Idle factory builds expected initial state — Фабрика idle создаёт корректное состояние")
    func test_idle_factory() {
        let idle = TabataSessionState.idle(
            totalSets: 4,
            totalCyclesPerSet: 8,
            totalDuration: 123
        )

        #expect(idle.currentIntervalIndex == 0)
        #expect(idle.currentPhase == .prepare)
        #expect(idle.remainingTime == 0)
        #expect(idle.totalDuration == 123)
        #expect(idle.elapsedTime == 0)
        #expect(idle.currentSet == 0)
        #expect(idle.totalSets == 4)
        #expect(idle.currentCycle == 0)
        #expect(idle.totalCyclesPerSet == 8)
        #expect(idle.progress == 0)
    }

    // MARK: Codable
    @Test("Codable roundtrip — Кодирование/декодирование без потерь")
    func test_codable_roundtrip() throws {
        let state = TabataSessionState(
            currentIntervalIndex: 2,
            currentPhase: .work,
            remainingTime: 7,
            totalDuration: 200,
            elapsedTime: 50,
            currentSet: 1,
            totalSets: 4,
            currentCycle: 3,
            totalCyclesPerSet: 8,
            progress: 0.25
        )

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(TabataSessionState.self, from: data)

        #expect(decoded == state)
    }
}
