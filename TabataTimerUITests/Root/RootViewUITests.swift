//
//  RootViewUITests.swift
//  TabataTimerUITests
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import XCTest

final class RootViewUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Basic tabs presence — Наличие вкладок
    func test_tabsExist_andCanBeSelected() throws {
        // Проверяем наличие трёх табов по их локализуемым лейблам
        let trainingTab = app.tabBars.buttons["Training"]
        let presetsTab = app.tabBars.buttons["Presets"]
        let settingsTab = app.tabBars.buttons["Settings"]

        XCTAssertTrue(trainingTab.waitForExistence(timeout: 3), "Training tab should exist")
        XCTAssertTrue(presetsTab.exists, "Presets tab should exist")
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")

        // Переходим на Presets и убеждаемся, что контент вкладки виден.
        presetsTab.tap()
        // Вместо поиска NavigationBar, ищем заголовочный текст или иконку-заглушку
        let presetsTitle = app.staticTexts["Presets"]
        let presetsIcon = app.images["list.bullet"]
        XCTAssertTrue(presetsTitle.waitForExistence(timeout: 2) || presetsIcon.exists, "Presets content should appear")

        // Переходим на Settings и аналогично проверяем контент
        settingsTab.tap()
        let settingsTitle = app.staticTexts["Settings"]
        let settingsIcon = app.images["gearshape.fill"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 2) || settingsIcon.exists, "Settings content should appear")

        // Возвращаемся на Training и проверяем контент вкладки (таймер/прогресс)
        trainingTab.tap()
        let remainingTimeStaticText = app.staticTexts["Remaining time"]
        XCTAssertTrue(remainingTimeStaticText.waitForExistence(timeout: 2), "Training content (Remaining time) should appear")
    }

    // MARK: - Training tab basics — Базовая проверка вкладки Тренировка
    func test_trainingTab_hasTimerAndControls() throws {
        let trainingTab = app.tabBars.buttons["Training"]
        if trainingTab.exists {
            trainingTab.tap()
        }

        // Проверяем наличие большого таймера
        let remainingTimeStaticText = app.staticTexts["Remaining time"]
        XCTAssertTrue(remainingTimeStaticText.waitForExistence(timeout: 2), "Remaining time label should exist")

        // Проверяем наличие индикатора прогресса
        let progressElement = app.otherElements["Progress"]
        let progressExists = progressElement.exists || app.staticTexts["Progress"].exists
        XCTAssertTrue(progressExists, "Progress element should exist")

        // Проверяем наличие кнопок управления (по лейблам)
        let startButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] %@", "Start")).firstMatch
        let resumeButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] %@", "Resume")).firstMatch
        let resetButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] %@", "Reset")).firstMatch

        XCTAssertTrue(startButton.exists || resumeButton.exists, "Start or Resume button should exist initially")
        XCTAssertTrue(resetButton.exists, "Reset button should exist")
    }
}

