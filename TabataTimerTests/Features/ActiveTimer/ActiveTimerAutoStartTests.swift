//
//  ActiveTimerAutoStartTests.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 03.12.2025.
//

import Foundation
import Testing
@testable import TabataTimer

@Suite("ActiveTimer — auto-start signal")
struct ActiveTimerAutoStartTests {

    @Test("Posting auto-start notification should be observable")
    func test_autoStart_notification_posts() async throws {
        // Этот тест не запускает UI, он проверяет, что нотификация может быть отправлена/получена.
        let name = Notification.Name.tabataAutoStartRequested
        var received = false

        let obs = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
            received = true
        }
        defer { NotificationCenter.default.removeObserver(obs) }

        NotificationCenter.default.post(name: name, object: nil)

        // Дадим main-циклу обработать.
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(received == true)
    }
}
