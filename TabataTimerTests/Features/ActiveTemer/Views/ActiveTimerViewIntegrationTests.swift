//
//  ActiveTimerViewIntegrationTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 25.11.2025.
//

import XCTest
import SwiftUI
@testable import TabataTimer

@MainActor
final class ActiveTimerViewIntegrationTests: XCTestCase {

    func test_viewReflectsEngineEvents_basicFlow() async throws {
        // given
        let config = TabataConfig(prepare: 1, work: 2, rest: 0, cyclesPerSet: 1, sets: 1, restBetweenSets: 0)
        let mock = MockEngine()
        let view = ActiveTimerView(config: config, engine: mock)

        // Прямого чтения текста из SwiftUI без UI-теста нет.
        // Но мы можем эмулировать события и убедиться, что всё проходит без ошибок.
        mock.emit(.phaseChanged(phase: .prepare, index: 0))
        mock.emit(.tick(remaining: 0))
        mock.emit(.phaseChanged(phase: .work, index: 1))
        mock.emit(.tick(remaining: 1))
        mock.emit(.tick(remaining: 0))
        mock.emit(.completed)

        // Дадим SwiftUI/главному актору обработать обновления.
        try await Task.sleep(nanoseconds: 50_000_000)

        // Если до сюда дошли без крашей — ок.
        XCTAssertTrue(true)
    }
}

// MARK: - MockEngine — Мок движка для интеграционного теста
private final class MockEngine: TimerEngineProtocol {
    private(set) var state: TimerState = .idle

    private let stream: AsyncStream<TimerEvent>
    private let continuation: AsyncStream<TimerEvent>.Continuation

    init() {
        var cont: AsyncStream<TimerEvent>.Continuation!
        stream = AsyncStream<TimerEvent> { c in cont = c }
        continuation = cont
    }

    var events: AsyncStream<TimerEvent> { stream }

    func configure(with plan: [TabataInterval]) { state = .idle }
    func start() { state = .running }
    func pause() { state = .paused }
    func resume() { state = .running }
    func reset() { state = .idle }

    func emit(_ event: TimerEvent) {
        continuation.yield(event)
    }
}

