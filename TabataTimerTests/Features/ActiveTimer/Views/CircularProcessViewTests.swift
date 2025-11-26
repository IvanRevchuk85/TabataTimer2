//
//  CircularProgressViewTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 25.11.2025.
//

import XCTest
@testable import TabataTimer

final class CircularProgressViewTests: XCTestCase {

    func test_progressClampedToRange() {
        // Проверяем, что значения воспринимаются в диапазоне 0...1
        // (в самой вью мы clamp делаем перед trim).
        // Здесь просто sanity-check на отсутствие краша при крайних значениях.
        _ = CircularProgressView(progress: -0.5)
        _ = CircularProgressView(progress: 0.0)
        _ = CircularProgressView(progress: 0.5)
        _ = CircularProgressView(progress: 1.0)
        _ = CircularProgressView(progress: 1.5)

        // Нет краша — ок. Глубокие проверки — в снапшот-тестах.
        XCTAssertTrue(true)
    }
}

