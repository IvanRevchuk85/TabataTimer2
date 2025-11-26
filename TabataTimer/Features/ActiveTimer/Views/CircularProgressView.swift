//
//  CircularProgressView.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import SwiftUI

// MARK: - CircularProgressView — Круговой прогресс
/// Simple circular progress with animation from 0 to 1.
/// Простой круговой прогресс с анимацией от 0 до 1.
struct CircularProgressView: View {
    var progress: Double      // 0...1
    var tint: Color = .green  // Accent color — Акцентный цвет

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 12)
                .foregroundStyle(Color.theme(.progressTrack))

            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(1, progress))))
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: progress)
        }
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

struct CircularProgressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            CircularProgressView(progress: 0.0, tint: .orange)
            CircularProgressView(progress: 0.33, tint: .blue)
            CircularProgressView(progress: 0.66, tint: .red)
            CircularProgressView(progress: 1.0, tint: .green)
        }
        .padding()
    }
}

