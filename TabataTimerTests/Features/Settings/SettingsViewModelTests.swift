//
//  SettingsViewModelTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 27.11.2025.
//

import XCTest
@testable import TabataTimer

// MARK: - MockSettingsStore — Простой мок для SettingsStoreProtocol (async/throws)
// MockSettingsStore — simple mock for SettingsStoreProtocol (async/throws).
final class MockSettingsStore: SettingsStoreProtocol {

    // MARK: State — Состояние
    /// Текущие настройки (как будто лежат в хранилище).
    /// Current settings (as if persisted in the store).
    var current: AppSettings

    // MARK: Call counters — Счетчики вызовов
    /// Счетчик вызовов load() — полезно проверять, что VM загружает ровно один раз.
    /// load() call counter — useful to ensure VM loads exactly once.
    private(set) var loadCallCount = 0
    /// Счетчик вызовов save()
    /// save() call counter
    private(set) var saveCallCount = 0
    /// Счетчик вызовов reset()
    /// reset() call counter
    private(set) var resetCallCount = 0

    // MARK: - Init — Инициализация
    /// Инициализация мока с начальными настройками.
    /// Initialize mock with initial settings.
    init(initial: AppSettings) {
        self.current = initial
    }

    // MARK: - SettingsStoreProtocol — Реализация
    /// Загрузка настроек (возвращаем текущее значение мока).
    /// Load settings (returns current mock value).
    func load() async throws -> AppSettings {
        loadCallCount += 1
        return current
    }

    /// Сохранение настроек (обновляем текущее значение мока).
    /// Save settings (updates current mock value).
    func save(_ settings: AppSettings) async throws {
        saveCallCount += 1
        current = settings
    }

    /// Сброс настроек к значениям по умолчанию.
    /// Reset settings to default values.
    func reset() async throws {
        resetCallCount += 1
        current = .default
    }
}

// MARK: - SettingsViewModelTests — Тесты ViewModel настроек
// SettingsViewModelTests — tests for SettingsViewModel (load/edit/save/reset).
@MainActor
final class SettingsViewModelTests: XCTestCase {

    // MARK: - Init & Load — Инициализация и загрузка
    /// ViewModel должен загрузить настройки из хранилища методом load().
    /// ViewModel should load settings from the store via load().
    func test_load_loadsSettingsFromStore() async throws {
        // given
        let stored = AppSettings(
            isSoundEnabled: false,
            isHapticsEnabled: false,
            theme: .dark,
            isAutoPauseEnabled: true
        )
        let store = MockSettingsStore(initial: stored)
        let viewModel = SettingsViewModel(store: store)

        // when
        await viewModel.load()

        // then
        XCTAssertEqual(store.loadCallCount, 1, "ViewModel should load settings once via load() — VM должен один раз загрузить настройки через load()")
        XCTAssertEqual(viewModel.settings.isSoundEnabled, stored.isSoundEnabled)
        XCTAssertEqual(viewModel.settings.isHapticsEnabled, stored.isHapticsEnabled)
        XCTAssertEqual(viewModel.settings.theme, stored.theme)
        XCTAssertEqual(viewModel.settings.isAutoPauseEnabled, stored.isAutoPauseEnabled)
    }

    // MARK: - Toggle Sound & Save — Переключение звука и сохранение
    /// Изменение звука должно отражаться в settings и сохраняться через store.save().
    /// Toggling sound should update settings and be persisted via store.save().
    func test_togglingSound_persistsUpdatedSettings() async throws {
        // given: sound is initially ON — Звук включён изначально.
        let initial = AppSettings(
            isSoundEnabled: true,
            isHapticsEnabled: true,
            theme: .system,
            isAutoPauseEnabled: false
        )
        let store = MockSettingsStore(initial: initial)
        let viewModel = SettingsViewModel(store: store)
        await viewModel.load()

        // when: user disables sound — пользователь выключает звук.
        viewModel.toggleSound(false)
        await viewModel.save()

        // then
        XCTAssertEqual(store.saveCallCount, 1, "Store.save(_:) must be called when settings change and save() invoked — save() должен вызываться при изменении настроек")
        XCTAssertEqual(store.current.isSoundEnabled, false)
        XCTAssertEqual(viewModel.settings.isSoundEnabled, false)
    }

    // MARK: - Toggle Haptics & Save — Переключение хаптик и сохранение
    /// Изменение хаптик должно сохраняться.
    /// Toggling haptics should be persisted.
    func test_togglingHaptics_persistsUpdatedSettings() async throws {
        // given
        let initial = AppSettings(
            isSoundEnabled: true,
            isHapticsEnabled: true,
            theme: .system,
            isAutoPauseEnabled: false
        )
        let store = MockSettingsStore(initial: initial)
        let viewModel = SettingsViewModel(store: store)
        await viewModel.load()

        // when
        viewModel.toggleHaptics(false)
        await viewModel.save()

        // then
        XCTAssertEqual(store.saveCallCount, 1)
        XCTAssertEqual(store.current.isHapticsEnabled, false)
        XCTAssertEqual(viewModel.settings.isHapticsEnabled, false)
    }

    // MARK: - Change Theme & Save — Изменение темы и сохранение
    /// Выбор темы должен сохраняться.
    /// Changing theme should be persisted.
    func test_changingTheme_persistsUpdatedSettings() async throws {
        // given
        let initial = AppSettings.default
        let store = MockSettingsStore(initial: initial)
        let viewModel = SettingsViewModel(store: store)
        await viewModel.load()

        // when
        viewModel.setTheme(.dark)
        await viewModel.save()

        // then
        XCTAssertEqual(store.saveCallCount, 1)
        XCTAssertEqual(store.current.theme, .dark)
        XCTAssertEqual(viewModel.settings.theme, .dark)
    }

    // MARK: - Toggle Auto-pause & Save — Переключение автопаузы и сохранение
    /// Переключение автопаузы должно сохраняться.
    /// Toggling auto-pause should be persisted.
    func test_togglingAutoPause_persistsUpdatedSettings() async throws {
        // given
        let initial = AppSettings(
            isSoundEnabled: true,
            isHapticsEnabled: true,
            theme: .system,
            isAutoPauseEnabled: false
        )
        let store = MockSettingsStore(initial: initial)
        let viewModel = SettingsViewModel(store: store)
        await viewModel.load()

        // when
        viewModel.toggleAutoPause(true)
        await viewModel.save()

        // then
        XCTAssertEqual(store.saveCallCount, 1)
        XCTAssertEqual(store.current.isAutoPauseEnabled, true)
        XCTAssertEqual(viewModel.settings.isAutoPauseEnabled, true)
    }

    // MARK: - Reset to Defaults — Сброс к значениям по умолчанию
    /// resetToDefaults() должен вызывать store.reset() и выставлять дефолтные настройки.
    /// resetToDefaults() should call store.reset() and set default settings.
    func test_resetToDefaults_setsDefaultSettings_andCallsReset() async throws {
        // given
        let initial = AppSettings(
            isSoundEnabled: false,
            isHapticsEnabled: false,
            theme: .dark,
            isAutoPauseEnabled: true
        )
        let store = MockSettingsStore(initial: initial)
        let viewModel = SettingsViewModel(store: store)
        await viewModel.load()

        // when
        await viewModel.resetToDefaults()

        // then
        XCTAssertEqual(store.resetCallCount, 1, "Store.reset() must be called — Должен быть вызван reset() у хранилища")
        XCTAssertEqual(viewModel.settings, .default, "ViewModel settings must be reset to defaults — Настройки VM должны стать дефолтными")
        XCTAssertEqual(store.current, .default, "Store current must be defaults after reset — В хранилище должны лежать дефолтные")
    }
}
