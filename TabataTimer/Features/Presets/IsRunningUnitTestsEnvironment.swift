//
//  IsRunningUnitTestsEnvironment.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 03.12.2025.
//

import SwiftUI

// MARK: - isRunningUnitTests EnvironmentKey
private struct IsRunningUnitTestsKey: EnvironmentKey {
    static let defaultValue: Bool = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
}

extension EnvironmentValues {
    var isRunningUnitTests: Bool {
        get { self[IsRunningUnitTestsKey.self] }
        set { self[IsRunningUnitTestsKey.self] = newValue }
    }
}
