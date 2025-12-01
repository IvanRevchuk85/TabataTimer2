//
//  PresetsTests.swift
//  TabataTimerTests
//
//  Created by Ivan Revchuk on 29.11.2025.
//

import Foundation
import Testing
@testable import TabataTimer

// MARK: - PresetsTests — Тесты пресетов (дефолтный пресет/конфиг)
/// Tests for presets: default config presence and correctness, duration consistency, basic display validation.
/// Тесты пресетов: наличие и корректность дефолтного конфига, согласованность длительности, базовая валидация отображения.
@Suite("Presets tests — Тесты пресетов")
struct PresetsTests {

    // MARK: Default preset/config — Дефолтный пресет/конфиг
    /// Verifies default TabataConfig values and basic derived properties.
    /// Проверяет значения по умолчанию TabataConfig и базовые производные свойства.
    @Test("Default preset config is valid — Дефолтный конфиг валиден")
    func test_default_preset_config_isValid() {
        let cfg = TabataConfig.default

        // Base expectations from spec — Базовые ожидания из ТЗ
        #expect(cfg.prepare == 10)
        #expect(cfg.work == 20)
        #expect(cfg.rest == 10)
        #expect(cfg.cyclesPerSet == 8)
        #expect(cfg.sets == 4)
        #expect(cfg.restBetweenSets == 60)

        // Derived values — Производные значения
        #expect(cfg.totalCycles == cfg.cyclesPerSet * cfg.sets)
        #expect(cfg.totalDuration() > 0)
    }

    // MARK: Duration consistency — Согласованность длительности
    /// Ensures totalDuration() equals duration(of: build(from:)).
    /// Гарантирует совпадение totalDuration() и duration(of: build(from:)).
    @Test("totalDuration() equals duration(of: build(from:)) — Формула совпадает с суммой плана")
    func test_totalDuration_matches_planDuration() {
        let cfg = TabataConfig.default
        let plan = TabataPlan.build(from: cfg)
        let formula = cfg.totalDuration()
        let byPlan = TabataPlan.duration(of: plan)

        #expect(formula == byPlan)

        // Sanity: last interval is .finished with 0 duration.
        // Проверка: последний интервал — .finished с нулевой длительностью.
        #expect(plan.last?.phase == .finished)
        #expect(plan.last?.duration == 0)
    }

    // MARK: Basic display validation — Базовая валидация отображения
    /// If you have a Preset model (name/description), uncomment and adapt.
    /// Если есть модель Preset (имя/описание), раскомментируйте и адаптируйте.
    /*
    @Test("Preset display fields are consistent — Отображаемые поля пресета корректны")
    func test_preset_display_fields() {
        let preset = Preset(id: UUID(), name: "Default", config: .default)
        #expect(!preset.name.isEmpty)
        // Optionally validate description/metadata — Опционально проверить описание/метаданные:
        // #expect(preset.details.contains("20/10 × 8 × 4"))
    }
    */
}
