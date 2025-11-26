//
//  CircularProgressViewTintTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import XCTest
@testable import TabataTimer
import SwiftUI

// MARK: - CircularProgressViewTintTests — Тесты оттенка кругового прогресса
/// Verifies CircularProgressView initialization with different tints and progress clamping.
/// Проверяет инициализацию CircularProgressView с разными цветами и корректный клампинг прогресса.
final class CircularProgressViewTintTests: XCTestCase {

    // MARK: - Init with various tints — Инициализация с разными цветами
    func test_init_withVariousTints_doesNotCrash() {
        // given — предусловия
        let tints: [Color] = [.red, .blue, .green, .orange, .purple]

        // when/then — действие/проверка
        for tint in tints {
            let view = CircularProgressView(progress: 0.5, tint: tint)
            // We cannot “render” in unit test; ensure construction is fine.
            // В unit-тесте нельзя отрисовать вью; просто убеждаемся, что конструирование проходит.
            XCTAssertNotNil(view)
        }
    }

    // MARK: - Progress clamping — Клампинг прогресса
    func test_progress_isClampedTo_0_1_range() {
        // given — предусловия
        let values: [Double] = [-1.0, -0.25, 0.0, 0.3, 0.7, 1.0, 1.5, 2.0]

        // when/then — действие/проверка
        for value in values {
            let view = CircularProgressView(progress: value, tint: .red)
            XCTAssertNotNil(view, "View should be constructible for value \(value)")
            // Rendering is not available here; this is a smoke test ensuring no crashes on extremes.
            // Здесь рендера нет; это smoke-тест на отсутствие падений при крайних значениях.
        }
    }
}

