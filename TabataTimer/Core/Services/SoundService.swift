//
//  SoundService.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 26.11.2025.
//

import Foundation
import AVFoundation
import AudioToolbox

// MARK: - SoundService — Реализация звукового сервиса
/// Minimal sound service using system sounds (AudioToolbox) and/or short AVAudioPlayer.
/// Минимальный звуковой сервис с использованием системных звуков (AudioToolbox) и/или AVAudioPlayer.
final class SoundService: SoundServiceProtocol {

    // Keep a short-lived player if you want to use bundled audio files.
    // Держим короткоживущий плеер, если хотим проигрывать файлы из бандла.
    private var player: AVAudioPlayer?

    // MARK: Phase sounds — Звуки смены фаз
    func playPhaseChange() {
        // Simple system sound as default — Простой системный звук по умолчанию
        AudioServicesPlaySystemSound(1104) // Tock
    }

    // MARK: Countdown tick — Звук тика обратного отсчёта
    func playCountdownTick() {
        AudioServicesPlaySystemSound(1057) // Short tick
    }

    // MARK: Completion — Завершение
    func playCompleted() {
        AudioServicesPlaySystemSound(1117) // Received message
    }

    // MARK: - (Optional) Play bundled file — (Опционально) Проигрывание файла из бандла
    /// Play a short audio file from bundle if present.
    /// Проиграть короткий аудиофайл из бандла, если он присутствует.
    func playBundledFile(named name: String, withExtension ext: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            // Silently ignore errors in this minimal service.
            // В минимальной реализации молча игнорируем ошибки.
        }
    }
}

