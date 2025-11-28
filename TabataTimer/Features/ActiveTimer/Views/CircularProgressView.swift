//
//  CircularProgressView.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import SwiftUI

// MARK: - CircularProgressView — Круговой прогресс
/// Simple circular progress with smooth animation from 0 to 1.
/// Простой круговой прогресс с плавной анимацией от 0 до 1.
struct CircularProgressView: View {

    // MARK: Public API — Публичные параметры
    /// Progress value in range 0...1.
    /// Значение прогресса в диапазоне 0...1.
    var progress: Double

    /// Foreground (progress) color.
    /// Цвет прогресс‑дуги.
    var tint: Color = .green

    /// Track (background circle) color.
    /// Цвет трека (фонового круга).
    var trackTint: Color = Color.theme(.progressTrack)

    /// Stroke width for both track and progress.
    /// Толщина линии для трека и прогресса.
    var lineWidth: CGFloat = 12

    // MARK: Internal — Вспомогательные вычисления
    /// Clamped progress to keep drawing safe.
    /// Клампим прогресс, чтобы отрисовка была безопасной.
    private var clampedProgress: Double {
        min(1.0, max(0.0, progress))
    }

    // MARK: Body — Разметка
    var body: some View {
        ZStack {
            // Track (background circle)
            // Трек (фон)
            Circle()
                .stroke(lineWidth: lineWidth)
                .foregroundStyle(trackTint)

            // Progress arc
            // Дуга прогресса
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
                // Start from top (12 o'clock)
                // Начинаем сверху (на 12 часах)
                .rotationEffect(.degrees(-90))
                // Smooth animation on progress change
                // Плавная анимация при изменении прогресса
                .animation(
                    .interpolatingSpring(stiffness: 200, damping: 28),
                    value: clampedProgress
                )
        }
        // Accessibility
        // Доступность
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(clampedProgress * 100)) percent")
    }
}

// MARK: - Previews — Превью
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
