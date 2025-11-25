//
//  ControlsBar.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 25.11.2025.
//

import SwiftUI

// MARK: - ControlsBar — Панель кнопок управления
/// Control bar with Start/Pause/Resume/Reset buttons.
/// Панель управления с кнопками Start/Pause/Resume/Reset.
struct ControlsBar: View {

    // MARK: UI State — UI-состояние
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
        HStack(spacing: 16) {
            switch state {
            case .idle:
                Button(action: onStart) {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive, action: onReset) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }

            case .running:
                Button(role: .none, action: onPause) {
                    Label("Pause", systemImage: "pause.fill")
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive, action: onReset) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }

            case .paused:
                Button(action: onResume) {
                    Label("Resume", systemImage: "playpause.fill")
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive, action: onReset) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }

            case .finished:
                Button(action: onStart) {
                    Label("Start", systemImage: "gobackward")
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive, action: onReset) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .font(.headline)
        .labelStyle(.titleAndIcon)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Controls")
    }
}

struct ControlsBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            ControlsBar(state: .idle, onStart: {}, onPause: {}, onResume: {}, onReset: {})
            ControlsBar(state: .running, onStart: {}, onPause: {}, onResume: {}, onReset: {})
            ControlsBar(state: .paused, onStart: {}, onPause: {}, onResume: {}, onReset: {})
            ControlsBar(state: .finished, onStart: {}, onPause: {}, onResume: {}, onReset: {})
        }
        .padding()
    }
}

