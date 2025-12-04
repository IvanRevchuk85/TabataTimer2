//
//  ControlsBar.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 25.11.2025.
//

import SwiftUI

struct ControlsBar: View {

    enum State {
        case idle
        case running
        case paused
        case finished
    }

    let state: State
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Левый край (внутренний отступ 5pt)
            if let left = leftButton {
                left
                    .frame(maxWidth: .infinity)
                    .padding(.leading, 5)
            } else {
                Spacer(minLength: 0)
            }

            // Было 12 → стало 8 (в 1.5 раза меньше)
            Spacer(minLength: 8)

            // Правый край (внутренний отступ 5pt)
            if let right = rightButton {
                right
                    .frame(maxWidth: .infinity)
                    .padding(.trailing, 5)
            } else {
                Spacer(minLength: 0)
            }
        }
        .font(.headline)
        .labelStyle(.titleAndIcon)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Controls")
    }

    private var leftButton: AnyView? {
        switch state {
        case .idle:
            return AnyView(
                Button(action: onStart) {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            )
        case .running:
            return AnyView(
                Button(action: onPause) {
                    Label("Pause", systemImage: "pause.fill")
                }
                .buttonStyle(.borderedProminent)
            )
        case .paused:
            return AnyView(
                Button(action: onResume) {
                    Label("Resume", systemImage: "playpause.fill")
                }
                .buttonStyle(.borderedProminent)
            )
        case .finished:
            return AnyView(
                Button(action: onStart) {
                    Label("Start", systemImage: "gobackward")
                }
                .buttonStyle(.borderedProminent)
            )
        }
    }

    private var rightButton: AnyView? {
        AnyView(resetButton)
    }

    private var resetButton: some View {
        Button(action: onReset) {
            Label("Reset", systemImage: "arrow.counterclockwise")
                .foregroundStyle(Color.white)
        }
        .tint(.red)
        .buttonStyle(.borderedProminent)
    }
}
