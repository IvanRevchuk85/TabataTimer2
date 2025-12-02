//
//  PresetsView.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 27.11.2025.
//

import SwiftUI

// MARK: - PresetsView — Экран списка пресетов
/// Список пресетов с возможностью создания, редактирования, удаления и выбора.
/// Простая реализация на SwiftUI. Интеграция с PresetsViewModel.
struct PresetsView: View {

    // MARK: StateObject — Модель представления
    @StateObject private var viewModel: PresetsViewModel

    // MARK: Local UI state — Локальные состояния формы
    @State private var isPresentingCreate: Bool = false
    @State private var draftName: String = ""
    @State private var draftConfig: TabataConfig = .default

    // MARK: - Init — Инициализация
    init(store: PresetsStoreProtocol = PresetsStore()) {
        _viewModel = StateObject(wrappedValue: PresetsViewModel(store: store))
    }

    // MARK: - Body — Тело
    var body: some View {
        List {
            if viewModel.presets.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No presets yet")
                            .foregroundStyle(.secondary)
                        Text("Create your first preset using the + button")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            } else {
                Section {
                    ForEach(viewModel.presets) { preset in
                        NavigationLink {
                            // Запуск выбранного пресета в таймере
                            ActiveTimerView(config: preset.config, engine: TimerEngine())
                                .navigationTitle(preset.name)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preset.name)
                                        .font(.headline)
                                    Text(configSummary(preset.config))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if viewModel.selected?.id == preset.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                        .accessibilityLabel("Selected")
                                }
                            }
                        }
                        .contextMenu {
                            Button("Rename") {
                                presentEdit(for: preset)
                            }
                            Button("Duplicate") {
                                Task { await duplicate(preset) }
                            }
                            Button(role: .destructive) {
                                Task { await viewModel.delete(id: preset.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await viewModel.delete(id: preset.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                let id = viewModel.presets[index].id
                                await viewModel.delete(id: id)
                            }
                        }
                    }
                } header: {
                    Text("Presets")
                }
            }
        }
        .overlay(alignedErrorOverlay)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task { await viewModel.load() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    startCreate()
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Presets")
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $isPresentingCreate) {
            NavigationStack {
                presetFormView(
                    title: draftFormTitle,
                    name: $draftName,
                    config: $draftConfig,
                    onCancel: { isPresentingCreate = false },
                    onSave: {
                        Task {
                            if let editing = editingPreset {
                                let updated = editing
                                    .renamed(draftName)
                                    .withConfig(draftConfig)
                                await viewModel.update(updated)
                            } else {
                                await viewModel.create(name: draftName, config: draftConfig)
                            }
                            isPresentingCreate = false
                            clearDraft()
                        }
                    }
                )
            }
        }
    }

    // MARK: - Edit state — Состояние редактирования
    @State private var editingPreset: Preset?

    private var draftFormTitle: String {
        editingPreset == nil ? "New Preset" : "Edit Preset"
    }

    private func startCreate() {
        editingPreset = nil
        draftName = ""
        draftConfig = .default
        isPresentingCreate = true
    }

    private func presentEdit(for preset: Preset) {
        editingPreset = preset
        draftName = preset.name
        draftConfig = preset.config
        isPresentingCreate = true
    }

    private func clearDraft() {
        editingPreset = nil
        draftName = ""
        draftConfig = .default
    }

    // MARK: - Duplicate — Дублирование
    private func duplicate(_ preset: Preset) async {
        let newName = preset.name + " Copy"
        await viewModel.create(name: newName, config: preset.config)
    }

    // MARK: - Error overlay — Оверлей ошибок
    @ViewBuilder
    private var alignedErrorOverlay: some View {
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

    // MARK: - Summary builder — Короткое описание конфигурации
    private func configSummary(_ c: TabataConfig) -> String {
        "prep \(c.prepare)s • work \(c.work)s • rest \(c.rest)s • cycles \(c.cyclesPerSet) • sets \(c.sets)"
    }

    // MARK: - Preset form — Форма создания/редактирования
    private func presetFormView(
        title: String,
        name: Binding<String>,
        config: Binding<TabataConfig>,
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) -> some View {
        Form {
            Section("Name") {
                TextField("Name", text: name)
                    .textInputAutocapitalization(.words)
            }

            Section("Configuration") {
                Stepper(value: Binding(
                    get: { config.wrappedValue.prepare },
                    set: { config.wrappedValue = TabataConfig(
                        prepare: $0,
                        work: config.wrappedValue.work,
                        rest: config.wrappedValue.rest,
                        cyclesPerSet: config.wrappedValue.cyclesPerSet,
                        sets: config.wrappedValue.sets,
                        restBetweenSets: config.wrappedValue.restBetweenSets
                    )}
                ), in: 0...300) {
                    HStack {
                        Text("Prepare")
                        Spacer()
                        Text("\(config.wrappedValue.prepare) s")
                            .foregroundStyle(.secondary)
                    }
                }

                Stepper(value: Binding(
                    get: { config.wrappedValue.work },
                    set: { config.wrappedValue = TabataConfig(
                        prepare: config.wrappedValue.prepare,
                        work: $0,
                        rest: config.wrappedValue.rest,
                        cyclesPerSet: config.wrappedValue.cyclesPerSet,
                        sets: config.wrappedValue.sets,
                        restBetweenSets: config.wrappedValue.restBetweenSets
                    )}
                ), in: 1...600) {
                    HStack {
                        Text("Work")
                        Spacer()
                        Text("\(config.wrappedValue.work) s")
                            .foregroundStyle(.secondary)
                    }
                }

                Stepper(value: Binding(
                    get: { config.wrappedValue.rest },
                    set: { config.wrappedValue = TabataConfig(
                        prepare: config.wrappedValue.prepare,
                        work: config.wrappedValue.work,
                        rest: $0,
                        cyclesPerSet: config.wrappedValue.cyclesPerSet,
                        sets: config.wrappedValue.sets,
                        restBetweenSets: config.wrappedValue.restBetweenSets
                    )}
                ), in: 0...600) {
                    HStack {
                        Text("Rest (between cycles)")
                        Spacer()
                        Text("\(config.wrappedValue.rest) s")
                            .foregroundStyle(.secondary)
                    }
                }

                Stepper(value: Binding(
                    get: { config.wrappedValue.cyclesPerSet },
                    set: { config.wrappedValue = TabataConfig(
                        prepare: config.wrappedValue.prepare,
                        work: config.wrappedValue.work,
                        rest: config.wrappedValue.rest,
                        cyclesPerSet: $0,
                        sets: config.wrappedValue.sets,
                        restBetweenSets: config.wrappedValue.restBetweenSets
                    )}
                ), in: 1...50) {
                    HStack {
                        Text("Cycles per set")
                        Spacer()
                        Text("\(config.wrappedValue.cyclesPerSet)")
                            .foregroundStyle(.secondary)
                    }
                }

                Stepper(value: Binding(
                    get: { config.wrappedValue.sets },
                    set: { config.wrappedValue = TabataConfig(
                        prepare: config.wrappedValue.prepare,
                        work: config.wrappedValue.work,
                        rest: config.wrappedValue.rest,
                        cyclesPerSet: config.wrappedValue.cyclesPerSet,
                        sets: $0,
                        restBetweenSets: config.wrappedValue.restBetweenSets
                    )}
                ), in: 1...50) {
                    HStack {
                        Text("Sets")
                        Spacer()
                        Text("\(config.wrappedValue.sets)")
                            .foregroundStyle(.secondary)
                    }
                }

                Stepper(value: Binding(
                    get: { config.wrappedValue.restBetweenSets },
                    set: { config.wrappedValue = TabataConfig(
                        prepare: config.wrappedValue.prepare,
                        work: config.wrappedValue.work,
                        rest: config.wrappedValue.rest,
                        cyclesPerSet: config.wrappedValue.cyclesPerSet,
                        sets: config.wrappedValue.sets,
                        restBetweenSets: $0
                    )}
                ), in: 0...900) {
                    HStack {
                        Text("Rest between sets")
                        Spacer()
                        Text("\(config.wrappedValue.restBetweenSets) s")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { onCancel() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { onSave() }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

// MARK: - Preview — Превью
struct PresetsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PresetsView(store: PresetsStore())
        }
    }
}
