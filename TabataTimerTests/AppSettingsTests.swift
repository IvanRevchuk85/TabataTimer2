//
//  AppSettingsTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 29.11.2025.
//

import Foundation
import Testing
import SwiftUI
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
            isAutoPauseEnabled: true,
            autoStartFromPreset: false,
            keepScreenAwake: false,
            countdownSoundEnabled: true,
            phaseChangeSoundEnabled: true,
            finishSoundEnabled: true,
            lightBackgroundColor: .system
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)

        #expect(decoded == original)
    }

    @Test("Backward compatibility: missing lightBackgroundColor defaults to .system — Обратная совместимость: отсутствие lightBackgroundColor по умолчанию .system")
    func test_backward_compatibility_missing_lightBackgroundColor() throws {
        // Сериализуем AppSettings старого формата (без lightBackgroundColor)
        let legacyDict: [String: Any] = [
            "isSoundEnabled": true,
            "isHapticsEnabled": false,
            "theme": "light",
            "isAutoPauseEnabled": true,
            "autoStartFromPreset": false,
            "keepScreenAwake": false,
            "countdownSoundEnabled": true,
            "phaseChangeSoundEnabled": false,
            "finishSoundEnabled": true
        ]
        let legacyData = try JSONSerialization.data(withJSONObject: legacyDict)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: legacyData)
        #expect(decoded.lightBackgroundColor == .system, "Should default to .system if field is missing")
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

