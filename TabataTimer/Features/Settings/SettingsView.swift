//
//  SettingsView.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 02.12.2025.
//

import SwiftUI

// Fallback: Define appSettingsDidChange locally if not provided by another module
extension Notification.Name {
    static let appSettingsDidChange = Notification.Name("appSettingsDidChange")
}

// MARK: - SettingsView — Экран настроек
struct SettingsView: View {

    @Environment(\.isRunningUnitTests) private var isRunningUnitTests
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            // MARK: Theme
            Section("Appearance") {
                Picker("Theme", selection: Binding(
                    get: { viewModel.settings.theme },
                    set: {
                        viewModel.setTheme($0)
                        // Немедленно уведомляем о смене темы
                        NotificationCenter.default.post(name: .appSettingsDidChange, object: nil)
                    }
                )) {
                    ForEach(AppSettings.Theme.allCases, id: \.self) { theme in
                        Text(theme.title).tag(theme)
                    }
                }
                
                // Light background color picker (only for light theme)
                if viewModel.settings.theme == .light || viewModel.settings.theme == .system {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Light mode background")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                        HStack(spacing: 12) {
                            ForEach(LightBackgroundColor.allCases) { preset in
                                Button(action: {
                                    // Change only if different to avoid unnecessary notifications
                                    if viewModel.settings.lightBackgroundColor != preset {
                                        viewModel.setLightBackgroundColor(preset)
                                        NotificationCenter.default.post(name: .appSettingsDidChange, object: nil)
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(preset.color)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.accentColor, lineWidth: viewModel.settings.lightBackgroundColor == preset ? 3 : 0)
                                            )
                                        if viewModel.settings.lightBackgroundColor == preset {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Color.accentColor)
                                                .background(.thinMaterial, in: Circle())
                                                .offset(y: 18)
                                                .font(.system(size: 18))
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text(preset.title))
                            }
                        }
                        .padding(.vertical, 1)
                    }
                }
            }

            // MARK: Sounds & Haptics
            Section("Feedback") {
                Toggle("Sounds", isOn: Binding(
                    get: { viewModel.settings.isSoundEnabled },
                    set: { viewModel.toggleSound($0) }
                ))
                Toggle("Haptics", isOn: Binding(
                    get: { viewModel.settings.isHapticsEnabled },
                    set: { viewModel.toggleHaptics($0) }
                ))

                Toggle("Countdown sound (3-2-1)", isOn: Binding(
                    get: { viewModel.settings.countdownSoundEnabled },
                    set: { viewModel.toggleCountdownSound($0) }
                ))
                .disabled(!viewModel.settings.isSoundEnabled)

                Toggle("Phase change sound", isOn: Binding(
                    get: { viewModel.settings.phaseChangeSoundEnabled },
                    set: { viewModel.togglePhaseChangeSound($0) }
                ))
                .disabled(!viewModel.settings.isSoundEnabled)

                Toggle("Finish sound", isOn: Binding(
                    get: { viewModel.settings.finishSoundEnabled },
                    set: { viewModel.toggleFinishSound($0) }
                ))
                .disabled(!viewModel.settings.isSoundEnabled)
            }

            // MARK: Behavior
            Section("Behavior") {
                Toggle("Auto-pause on background", isOn: Binding(
                    get: { viewModel.settings.isAutoPauseEnabled },
                    set: { viewModel.toggleAutoPause($0) }
                ))
                Toggle("Auto-start when opening preset", isOn: Binding(
                    get: { viewModel.settings.autoStartFromPreset },
                    set: { viewModel.toggleAutoStartFromPreset($0) }
                ))
                Toggle("Keep screen awake during training", isOn: Binding(
                    get: { viewModel.settings.keepScreenAwake },
                    set: { viewModel.toggleKeepScreenAwake($0) }
                ))
                Toggle(
                    "Show on-screen phrases during workout",
                    isOn: Binding(
                        get: { viewModel.settings.inWorkoutPhrasesEnabled },
                        set: { viewModel.toggleInWorkoutPhrases($0) }
                    )
                )
            }

            // MARK: Actions
            Section {
                Button(role: .destructive) {
                    if !isRunningUnitTests {
                        Task { 
                            await viewModel.resetToDefaults()
                            NotificationCenter.default.post(name: .appSettingsDidChange, object: nil)
                        }
                        // После сброса тоже уведомим про возможную смену темы
                    }
                } label: {
                    Text("Reset to Defaults")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listRowBackground(Color.clear)
        .background(Color.clear)
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if !isRunningUnitTests {
                        Task {
                            await viewModel.save()
                            // Уведомим корень о сохранении (в т.ч. теме)
                            NotificationCenter.default.post(name: .appSettingsDidChange, object: nil)
                        }
                    }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .task {
            guard !isRunningUnitTests else { return }
            await viewModel.load()
        }
        .overlay(errorOverlay)
    }

    @ViewBuilder
    private var errorOverlay: some View {
        if let message = viewModel.errorMessage {
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                    Spacer()
                    Button("Dismiss") {
                        viewModel.errorMessage = nil
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding()
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut, value: message)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
    }
}

// MARK: - SettingsViewModel extension for LightBackgroundColor

extension SettingsViewModel {
    func setLightBackgroundColor(_ color: LightBackgroundColor) {
        settings.lightBackgroundColor = color
    }
}

