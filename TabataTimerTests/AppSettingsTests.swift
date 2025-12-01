//
//  AppSettingsTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 29.11.2025.
//

import Foundation
import Testing
@testable import TabataTimer

// MARK: - AppSettingsTests — Тесты настроек приложения
@Suite("AppSettings tests — Тесты настроек")
struct AppSettingsTests {

    // MARK: Defaults
    @Test("Default values — Значения по умолчанию")
    func test_defaults() {
        let s = AppSettings.default
        #expect(s.isSoundEnabled == true)
        #expect(s.isHapticsEnabled == true)
        #expect(s.theme == .system)
        #expect(s.isAutoPauseEnabled == false)
    }

    // MARK: Theme
    @Test("Theme titles — Названия тем")
    func test_theme_titles() {
        #expect(AppSettings.Theme.system.title == "System")
        #expect(AppSettings.Theme.light.title == "Light")
        #expect(AppSettings.Theme.dark.title == "Dark")
    }

    // MARK: Codable
    @Test("Codable roundtrip — Кодирование/декодирование")
    func test_codable_roundtrip() throws {
        let original = AppSettings(
            isSoundEnabled: false,
            isHapticsEnabled: true,
            theme: .dark,
            isAutoPauseEnabled: true
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        #expect(decoded == original)
    }

    // MARK: Equatable/Hashable
    @Test("Hashable/Equatable behavior — Поведение сравнения и хеширования")
    func test_hashable_equatable() {
        let a = AppSettings.default
        var b = AppSettings.default
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)

        b.isSoundEnabled.toggle()
        #expect(a != b)
    }
}
