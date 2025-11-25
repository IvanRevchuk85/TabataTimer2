//
//  PhaseTitleView.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 25.11.2025.
//

import SwiftUI

// MARK: - PhaseTitleView — Заголовок текущей фазы
/// A small header that displays current phase name and color accent.
/// Небольшой заголовок, показывающий текущую фазу и цветовой акцент.
struct PhaseTitleView: View {
    let phase: TabataPhase

    var body: some View {
        Text(title(for: phase))
            .font(.title2.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(backgroundColor(for: phase).opacity(0.15))
            .foregroundStyle(backgroundColor(for: phase))
            .clipShape(Capsule())
            .accessibilityLabel("Phase")
            .accessibilityValue(title(for: phase))
    }

    // MARK: - Helpers — Вспомогательные
    private func title(for phase: TabataPhase) -> String {
        phase.title
    }

    private func backgroundColor(for phase: TabataPhase) -> Color {
        switch phase {
        case .prepare: return .orange
        case .work: return .red
        case .rest: return .blue
        case .restBetweenSets: return .purple
        case .finished: return .green
        }
    }
}

struct PhaseTitleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            PhaseTitleView(phase: .prepare)
            PhaseTitleView(phase: .work)
            PhaseTitleView(phase: .rest)
            PhaseTitleView(phase: .restBetweenSets)
            PhaseTitleView(phase: .finished)
        }
        .padding()
    }
}

