//
//  PhraseRepository.swift
//  TabataTimer
//
//  Created by Ivan Revchuk on 05.12.2025.
//

import Foundation

/// Repository of humorous phrases per phase and language.
/// Репозиторий фраз по фазам и языкам.
enum PhraseRepository {

    // Supported languages (auto-selected by locale). / Поддерживаемые языки.
    enum Lang: String { case en, ru, uk, es }

    /// Returns random phrase for given phase and language.
    /// Возвращает случайную фразу для указанной фазы и языка.
    /// - parameter excluding: phrase to avoid repeating immediately.
    /// - parameter excluding: фраза, которую нужно избежать (чтобы не повторять подряд).
    static func randomPhrase(
        for phase: TabataPhase,
        lang: Lang,
        excluding: String? = nil
    ) -> String? {
        let pool: [String]

        switch (phase, lang) {
        // PREPARE — до 10 фраз
        case (.prepare, .en): pool = [
            "Last chance to quit",
            "Breathe in…",
            "Warm up your will",
            "No excuses today",
            "Ready or not…",
            "Lock in, no doubts",
            "You showed up, that counts",
            "This is the easy part",
            "Calm mind, sharp body",
            "Focus beats motivation"
        ]
        case (.prepare, .ru): pool = [
            "Последний шанс передумать",
            "Вдохни глубже…",
            "Разминай силу воли",
            "Без отмаз сегодня",
            "Готов — не готов…",
            "Соберись, это ещё не больно",
            "Ты уже сделал сложную часть — пришёл",
            "Сейчас решаешь, кем будешь",
            "Тише дыши, глубже работай",
            "Фокус важнее настроения"
        ]
        case (.prepare, .uk): pool = [
            "Останній шанс передумати",
            "Вдихни глибше…",
            "Розігрій силу волі",
            "Без відмаз сьогодні",
            "Готовий чи ні…",
            "Зберися, це ще не боляче",
            "Ти вже зробив складне — прийшов",
            "Зараз вирішуєш, ким будеш",
            "Дихай спокійно, працюй глибоко",
            "Фокус важливіший за настрій"
        ]
        case (.prepare, .es): pool = [
            "Última oportunidad de rendirte",
            "Inhala profundo…",
            "Calienta tu voluntad",
            "Sin excusas hoy",
            "Listo o no…",
            "Concéntrate, no dudes",
            "Ya hiciste la parte difícil: venir",
            "Este es el punto de decisión",
            "Mente calma, cuerpo listo",
            "Enfoque > motivación"
        ]

        // WORK — до 10 фраз
        case (.work, .en): pool = [
            "Push, don’t negotiate",
            "You asked for this",
            "Legs are lying",
            "This is the rep that counts",
            "Don’t be average",
            "Pain is data",
            "You can rest later",
            "Strong exhale, strong rep",
            "One more, always one more",
            "This minute changes the next 23 hours"
        ]
        case (.work, .ru): pool = [
            "Жми, не торгуйся",
            "Ты сам этого хотел",
            "Ноги врут, продолжай",
            "Вот этот подход и считается",
            "Не будь средним",
            "Боль — это просто данные",
            "Отдохнёшь потом",
            "Выдохни сильнее — повтор сильнее",
            "Всегда ещё один повтор",
            "Эта минута меняет следующие 23 часа"
        ]
        case (.work, .uk): pool = [
            "Тисни, не торгуйся",
            "Ти сам цього хотів",
            "Ноги брешуть",
            "Саме цей підхід має значення",
            "Не будь середнім",
            "Біль — це просто дані",
            "Відпочинеш потім",
            "Сильний видих — сильний підхід",
            "Завжди ще один повтор",
            "Ця хвилина змінює наступні 23 години"
        ]
        case (.work, .es): pool = [
            "Empuja, no negocies",
            "Tú pediste esto",
            "Las piernas mienten",
            "Esta es la repetición que cuenta",
            "No seas promedio",
            "El dolor es información",
            "Descansarás luego",
            "Exhala fuerte, rep fuerte",
            "Siempre uno más",
            "Este minuto cambia las próximas 23 horas"
        ]

        // REST — до 10 фраз
        case (.rest, .en): pool = [
            "Nice. Don’t get too comfy",
            "Breathe. Next round soon",
            "You’re earning this rest",
            "Shake it out, stay ready",
            "Heart’s working, good",
            "Relax the face, not the effort",
            "Deep nose in, slow mouth out",
            "This is where you recover, not quit",
            "Walk it off, don’t sit",
            "Control the breathing, control the round"
        ]
        case (.rest, .ru): pool = [
            "Норм, только не расслабляйся",
            "Дыши. Скоро следующий раунд",
            "Ты заслужил эту паузу",
            "Встряхнись, будь наготове",
            "Сердце пашет — это хорошо",
            "Расслабь лицо, не усилие",
            "Через нос — вдох, через рот — выдох",
            "Здесь ты восстанавливаешься, а не сдаёшься",
            "Походи, не садись",
            "Контролируешь дыхание — контролируешь раунд"
        ]
        case (.rest, .uk): pool = [
            "Норм, тільки не розслабляйся",
            "Дихай. Скоро наступний раунд",
            "Ти заслужив цю паузу",
            "Струснись, будь напоготові",
            "Серце працює — і це добре",
            "Розслаб обличчя, не зусилля",
            "Вдих носом, видих ротом",
            "Тут ти відновлюєшся, не здаєшся",
            "Пройдися, не сідай",
            "Контролюєш дихання — контролюєш раунд"
        ]
        case (.rest, .es): pool = [
            "Bien. No te acomodes",
            "Respira. Próxima ronda pronto",
            "Te ganaste este descanso",
            "Sacúdete, mantente listo",
            "El corazón trabaja, bien",
            "Relaja la cara, no el esfuerzo",
            "Inhala por la nariz, exhala por la boca",
            "Aquí recuperas, no te rindes",
            "Camina, no te sientes",
            "Controla la respiración, controlas la ronda"
        ]

        // REST BETWEEN SETS — до 10
        case (.restBetweenSets, .en): pool = [
            "New set, new you",
            "You survived that. Impressive",
            "Half human, half engine",
            "Water. Now.",
            "Check posture, not Instagram",
            "Scan the body: what’s tight?",
            "Reset your form, not your goals",
            "Short rest, long progress",
            "You’re not done, just reloading",
            "Walk like you’ve earned it"
        ]
        case (.restBetweenSets, .ru): pool = [
            "Новый сет — новая версия тебя",
            "Это пережил. Уже неплохо",
            "Наполовину человек, наполовину двигатель",
            "Вода. Сейчас.",
            "Проверь осанку, а не Инстаграм",
            "Просканируй тело: где зажим?",
            "Правь технику, не цели",
            "Короткий отдых — длинный прогресс",
            "Ты не закончил, ты перезаряжаешься",
            "Ходи так, будто заработал"
        ]
        case (.restBetweenSets, .uk): pool = [
            "Новий сет — нова версія тебе",
            "Це пережив. Вже непогано",
            "Наполовину людина, наполовину двигун",
            "Вода. Зараз.",
            "Перевір поставу, а не Instagram",
            "Проскануй тіло: де затиск?",
            "Прав техніку, не цілі",
            "Короткий відпочинок — довгий прогрес",
            "Ти не закінчив, ти перезаряджаєшся",
            "Ходи так, ніби заробив"
        ]
        case (.restBetweenSets, .es): pool = [
            "Nuevo set, nuevo tú",
            "Sobreviviste a eso. Impresionante",
            "Mitad humano, mitad motor",
            "Agua. Ahora.",
            "Revisa la postura, no Instagram",
            "Escanea el cuerpo: ¿dónde está la tensión?",
            "Corrige la técnica, no el objetivo",
            "Descanso corto, progreso largo",
            "No has terminado, solo recargas",
            "Camina como si lo hubieras ganado"
        ]

        // FINISHED — до 10
        case (.finished, .en): pool = [
            "Session complete. Still alive?",
            "Save this. Repeat later",
            "Future you says thanks",
            "Screenshot this victory",
            "Consistency beats intensity",
            "You did more than nothing",
            "This is how athletes are built",
            "Your sofa did not win today",
            "Mark this day in your head",
            "Next time, just one round more"
        ]
        case (.finished, .ru): pool = [
            "Сессия закончена. Всё ещё жив?",
            "Запомни это. Повтори позже",
            "Будущий ты говорит спасибо",
            "Зафиксируй победу скриншотом",
            "Системность сильнее разового героизма",
            "Ты сделал больше, чем ничего",
            "Так строятся атлеты",
            "Сегодня диван не победил",
            "Отметь этот день в голове",
            "В следующий раз — хотя бы на раунд больше"
        ]
        case (.finished, .uk): pool = [
            "Сесію завершено. Ще живий?",
            "Запам’ятай це. Повтори пізніше",
            "Майбутній ти каже «дякую»",
            "Зафіксуй перемогу скріном",
            "Системність сильніша за разовий героїзм",
            "Ти зробив більше, ніж нічого",
            "Так будують атлетів",
            "Сьогодні диван не переміг",
            "Познач цей день у голові",
            "Наступного разу — хоча б на раунд більше"
        ]
        case (.finished, .es): pool = [
            "Sesión completa. ¿Sigues vivo?",
            "Guárdalo. Repite luego",
            "Tu yo del futuro dice gracias",
            "Captura esta victoria",
            "La constancia gana a la intensidad",
            "Hiciste más que nada",
            "Así se construyen atletas",
            "Hoy el sofá no ganó",
            "Marca este día en tu mente",
            "La próxima vez, un round más"
        ]

        default:
            pool = []
        }

        guard !pool.isEmpty else { return nil }

        // Avoid immediate repetition / Избегаем повторения подряд
        if let excluding, pool.count > 1 {
            let filtered = pool.filter { $0 != excluding }
            if let candidate = filtered.randomElement() {
                return candidate
            }
        }

        return pool.randomElement()
    }
}
