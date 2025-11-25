//
//  PhaseTitleViewTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 25.11.2025.
//

import XCTest
@testable import TabataTimer

final class PhaseTitleViewTests: XCTestCase {

    func test_phaseTitleUsesPhaseTitleString() {
        // Просто проверим, что у фаз есть title (метаданные),
        // а PhaseTitleView использует phase.title.
        XCTAssertEqual(TabataPhase.prepare.title, "Prepare")
        XCTAssertEqual(TabataPhase.work.title, "Work")
        XCTAssertEqual(TabataPhase.rest.title, "Rest")
        XCTAssertEqual(TabataPhase.restBetweenSets.title, "Rest Between Sets")
        XCTAssertEqual(TabataPhase.finished.title, "Finished")
    }
}

