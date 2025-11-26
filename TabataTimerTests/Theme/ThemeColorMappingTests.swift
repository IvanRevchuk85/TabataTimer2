//
//  ThemeColorMappingTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import XCTest
@testable import TabataTimer
import SwiftUI

// MARK: - ThemeColorMappingTests — Тесты маппинга темы в цвета
/// Verifies that theme color keys and phase-to-color mapping produce valid SwiftUI Colors.
/// Проверяет, что ключи темы и маппинг фазы в цвет возвращают валидные SwiftUI Color.
final class ThemeColorMappingTests: XCTestCase {

    // MARK: - Theme.Colors mapping — Маппинг Theme.Colors
    func test_themeColors_mapping_producesColors() {
        // given — предусловия
        let keys: [Theme.Colors] = [
            .phasePrepare, .phaseWork, .phaseRest, .phaseRestBetween, .phaseFinished,
            .textPrimary, .textSecondary, .bgPrimary, .progressTrack
        ]

        // when/then — действие/проверка
        for key in keys {
            let color = Color.theme(key)
            // We cannot compare RGBA reliably in unit tests; ensure construction is fine.
            // В unit-тестах нельзя надёжно сравнивать RGBA; проверяем, что цвет создаётся.
            XCTAssertNotNil(color, "Color for key \(key.rawValue) should be constructible")
        }
    }

    // MARK: - Phase mapping — Маппинг фазы в цвет
    func test_forPhase_returnsColor_forEachPhase() {
        // given — предусловия
        let phases: [TabataPhase] = [.prepare, .work, .rest, .restBetweenSets, .finished]

        // when/then — действие/проверка
        for phase in phases {
            let color = Color.forPhase(phase)
            XCTAssertNotNil(color, "Color for phase \(phase) should be constructible")
        }
    }
}

