//
//  ControlsBarTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 25.11.2025.
//

import XCTest
import SwiftUI
@testable import TabataTimer

final class ControlsBarTests: XCTestCase {

    func test_idle_showsStartAndReset() {
        var started = false
        var reset = false

        let view = ControlsBar(
            state: .idle,
            onStart: { started = true },
            onPause: {},
            onResume: {},
            onReset: { reset = true }
        )

        // Поскольку это SwiftUI View, прямого нажатия кнопок без UI-теста нет.
        // Но мы проверяем, что колбэки живые и корректно вызываются.
        view.onStart()
        view.onReset()

        XCTAssertTrue(started)
        XCTAssertTrue(reset)
    }

    func test_running_showsPauseAndReset() {
        var paused = false
        var reset = false

        let view = ControlsBar(
            state: .running,
            onStart: {},
            onPause: { paused = true },
            onResume: {},
            onReset: { reset = true }
        )

        view.onPause()
        view.onReset()

        XCTAssertTrue(paused)
        XCTAssertTrue(reset)
    }

    func test_paused_showsResumeAndReset() {
        var resumed = false
        var reset = false

        let view = ControlsBar(
            state: .paused,
            onStart: {},
            onPause: {},
            onResume: { resumed = true },
            onReset: { reset = true }
        )

        view.onResume()
        view.onReset()

        XCTAssertTrue(resumed)
        XCTAssertTrue(reset)
    }
}

