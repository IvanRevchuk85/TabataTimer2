//
//  SettingsStoreTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 27.11.2025.
//

import XCTest
@testable import TabataTimer

// MARK: - SettingsStoreTests — Тесты хранилища настроек (UserDefaults)
/// SettingsStoreTests — tests for SettingsStore backed by UserDefaults.
/// Тесты SettingsStore, работающего поверх UserDefaults.
final class SettingsStoreTests: XCTestCase {

    // MARK: Fixtures — Тестовые зависимости
    /// Dedicated UserDefaults suite for a single test case.
    /// Отдельный UserDefaults-suite для каждого теста.
    private var userDefaults: UserDefaults!
    private var store: SettingsStore!

    // MARK: - setUp / tearDown — Подготовка и очистка
    override func setUpWithError() throws {
        try super.setUpWithError()

        // Unique suite name per test to avoid cross-test interference.
        // Уникальное имя suite для каждого теста, чтобы тесты не влияли друг на друга.
        let suiteName = "SettingsStoreTests-\(UUID().uuidString)"

        guard let ud = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create UserDefaults suite")
            return
        }

        userDefaults = ud
        // Инициализируем Store с этим suite и отдельным ключом.
        store = SettingsStore(defaults: userDefaults, storageKey: "test.settings.key")
    }

    // MARK: - Load — Загрузка по умолчанию
    /// load() should return AppSettings.default when nothing was saved yet.
    /// load() должен вернуть AppSettings.default, если ничего не сохранено.
    func test_load_returnsDefaultSettings_whenNoDataSaved() async throws {
        // when
        let settings = try await store.load()

        // then
        XCTAssertTrue(settings.isSoundEnabled, "Sound should be enabled by default")
        XCTAssertTrue(settings.isHapticsEnabled, "Haptics should be enabled by default")
        XCTAssertFalse(settings.isAutoPauseEnabled, "Auto-pause default is expected to be false")
    }

    // MARK: - Save/Load — Сохранение и повторная загрузка
    func test_save_thenLoad_returnsSameSettings() async throws {
        // given
        let custom = AppSettings(
            isSoundEnabled: false,
            isHapticsEnabled: true,
            theme: .dark,
            isAutoPauseEnabled: true
        )

        // when
        try await store.save(custom)
        let loaded = try await store.load()

        // then
        XCTAssertEqual(loaded.isSoundEnabled, custom.isSoundEnabled)
        XCTAssertEqual(loaded.isHapticsEnabled, custom.isHapticsEnabled)
        XCTAssertEqual(loaded.theme, custom.theme)
        XCTAssertEqual(loaded.isAutoPauseEnabled, custom.isAutoPauseEnabled)
    }

    // MARK: - Overwrite — Перезапись настроек
    func test_secondSave_overwritesPreviousSettings() async throws {
        // given
        let first = AppSettings(
            isSoundEnabled: true,
            isHapticsEnabled: true,
            theme: .light,
            isAutoPauseEnabled: false
        )
        let second = AppSettings(
            isSoundEnabled: false,
            isHapticsEnabled: false,
            theme: .dark,
            isAutoPauseEnabled: true
        )

        try await store.save(first)

        // when
        try await store.save(second)
        let loaded = try await store.load()

        // then
        XCTAssertEqual(loaded.isSoundEnabled, second.isSoundEnabled)
        XCTAssertEqual(loaded.isHapticsEnabled, second.isHapticsEnabled)
        XCTAssertEqual(loaded.theme, second.theme)
        XCTAssertEqual(loaded.isAutoPauseEnabled, second.isAutoPauseEnabled)
    }

    // MARK: - Reset — Сброс хранилища
    func test_reset_removesStoredSettings_andNextLoadReturnsDefaults() async throws {
        // given
        let custom = AppSettings(
            isSoundEnabled: false,
            isHapticsEnabled: false,
            theme: .light,
            isAutoPauseEnabled: true
        )
        try await store.save(custom)

        // sanity check
        do {
            let loaded = try await store.load()
            XCTAssertEqual(loaded, custom)
        }

        // when
        try await store.reset()

        // then
        let afterReset = try await store.load()
        XCTAssertEqual(afterReset, .default, "After reset, load() should return defaults")
    }
}
