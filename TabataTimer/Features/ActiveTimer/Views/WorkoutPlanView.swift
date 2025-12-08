//
//  WorkoutPlanView.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 08.12.2025.
//

import SwiftUI

struct WorkoutPlanView: View {
    let title: String
    let items: [ActiveTimerViewModel.IntervalDisplayItem]

    // Суммы по категориям
    private var totalSeconds: Int {
        items
            .filter { $0.phase != .finished }
            .reduce(0) { $0 + max(0, $1.duration) }
    }

    private var workSeconds: Int {
        items
            .filter { $0.phase == .work }
            .reduce(0) { $0 + max(0, $1.duration) }
    }

    private var restSeconds: Int {
        items
            .filter { $0.phase == .rest || $0.phase == .restBetweenSets }
            .reduce(0) { $0 + max(0, $1.duration) }
    }

    private var prepareSeconds: Int {
        items
            .filter { $0.phase == .prepare }
            .reduce(0) { $0 + max(0, $1.duration) }
    }

    var body: some View {
        List {
            // Верхний сводный блок
            Section {
                summaryRow
            }

            // Список интервалов
            Section {
                ForEach(items) { item in
                    HStack(spacing: 12) {
                        // Цветной индикатор фазы
                        Circle()
                            .fill(Color.forPhase(item.phase))
                            .frame(width: 10, height: 10)

                        // Название фазы + Set/Cycle
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.phase.title)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.forPhase(item.phase))

                            HStack(spacing: 8) {
                                Text("Set \(item.setNumber)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.theme(.textSecondary))

                                if item.cycleIndex >= 0 {
                                    Text("Cycle \(item.cycleNumber)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Color.theme(.textSecondary))
                                }
                            }
                        }

                        Spacer()

                        // Длительность справа, формат mm:ss как в ActiveTimerView
                        Text(format(seconds: item.duration))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Color.forPhase(item.phase))
                    }
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(accessibilityLabel(for: item))
                }
            }
        }
        .navigationTitle(title)
    }

    // MARK: - Summary view (top)
    private var summaryRow: some View {
        VStack(spacing: 10) {
            // Total
            HStack {
                Label("Total", systemImage: "sum")
                    .labelStyle(.titleAndIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.theme(.textSecondary))
                Spacer()
                Text(format(seconds: totalSeconds))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.theme(.textSecondary))
            }

            // Work
            HStack {
                Text("Work")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.forPhase(.work))
                Spacer()
                Text(format(seconds: workSeconds))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.forPhase(.work))
            }

            // Rest (cycles + between sets)
            HStack {
                Text("Rest")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.forPhase(.rest))
                Spacer()
                Text(format(seconds: restSeconds))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.forPhase(.rest))
            }

            // Prepare
            HStack {
                Text("Prepare")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.forPhase(.prepare))
                Spacer()
                Text(format(seconds: prepareSeconds))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.forPhase(.prepare))
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Helpers
    private func format(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func accessibilityLabel(for item: ActiveTimerViewModel.IntervalDisplayItem) -> String {
        let base = "\(item.phase.title), set \(item.setNumber)"
        let cyclePart = item.cycleIndex >= 0 ? ", cycle \(item.cycleNumber)" : ""
        return base + cyclePart + ", duration \(item.duration) seconds"
    }
}

struct WorkoutPlanView_Previews: PreviewProvider {
    static var previews: some View {
        let samples: [ActiveTimerViewModel.IntervalDisplayItem] = [
            .init(id: UUID(), phase: .prepare,           duration: 10, setIndex: 0, cycleIndex: -1),
            .init(id: UUID(), phase: .work,              duration: 20, setIndex: 0, cycleIndex: 0),
            .init(id: UUID(), phase: .rest,              duration: 10, setIndex: 0, cycleIndex: 0),
            .init(id: UUID(), phase: .work,              duration: 20, setIndex: 0, cycleIndex: 1),
            .init(id: UUID(), phase: .rest,              duration: 10, setIndex: 0, cycleIndex: 1),
            .init(id: UUID(), phase: .restBetweenSets,   duration: 30, setIndex: 0, cycleIndex: -1),
            .init(id: UUID(), phase: .finished,          duration: 0,  setIndex: 0, cycleIndex: -1),
        ]
        NavigationStack {
            WorkoutPlanView(
                title: "Workout plan",
                items: samples
            )
        }
    }
}
