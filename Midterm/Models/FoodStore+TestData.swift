import Foundation

// MARK: - Test data
// For trying the app with LOTS of food (layout, scrolling, charts, recipes).
// Opened from the "Test data" menu (⋯) at the top of My Fridge.
// Uses a fixed random seed, so every load gives the same 60 items.

extension FoodStore {

    /// 60 fridge items across every category and freshness level,
    /// plus ~90 used / wasted records spread over the last 6 weeks.
    func loadStressTestData(itemCount: Int = 60, historyCount: Int = 90) {
        var random = SeededRandom(seed: 2026)
        let calendar = Calendar.current
        let presets = IngredientPresetService.shared.loadPresets()
        guard !presets.isEmpty else { return }

        func date(_ daysFromToday: Int) -> Date {
            calendar.date(byAdding: .day, value: daysFromToday, to: calendar.startOfDay(for: Date())) ?? Date()
        }

        func makeItem(from preset: IngredientPreset, name: String? = nil, expiresIn: Int) -> FoodItem {
            FoodItem(
                name: name ?? preset.name,
                category: preset.category,
                addedDate: date(-random.int(in: 0...6)),
                expirationDate: date(expiresIn),
                quantity: random.int(in: 1...6),
                estimatedValue: preset.estimatedValue,
                carbonFactor: preset.carbonFactor
            )
        }

        // Spread of days left so every HP level shows up:
        // expired, today, urgent (1–2), use soon (3–6), fresh (7+).
        let expiryPool = [-3, -1, 0, 0, 1, 1, 2, 2, 3, 4, 5, 5, 6, 7, 9, 12, 14, 20]

        var items: [FoodItem] = []
        var shuffled = presets
        random.shuffle(&shuffled)
        for preset in shuffled.prefix(itemCount - 2) {
            items.append(makeItem(from: preset, expiresIn: expiryPool[random.int(in: 0...(expiryPool.count - 1))]))
        }

        // Two very long names to test text wrapping / truncation.
        if let tomato = presets.first(where: { $0.name == "Cherry Tomato" }) {
            items.append(makeItem(from: tomato, name: "Organic Heirloom Rainbow Cherry Tomatoes (Family Pack)", expiresIn: 1))
        }
        if let milk = presets.first(where: { $0.name == "Whole Milk" }) {
            items.append(makeItem(from: milk, name: "Ultra-Filtered Lactose-Free Whole Milk Half Gallon", expiresIn: 4))
        }

        // History: about 75% used, 25% wasted, over the last 42 days.
        var records: [FoodItem] = []
        for _ in 0..<historyCount {
            let preset = presets[random.int(in: 0...(presets.count - 1))]
            let finished = calendar.date(byAdding: .hour, value: random.int(in: 8...20),
                                         to: date(-random.int(in: 0...41))) ?? Date()
            var record = makeItem(from: preset, expiresIn: 0)
            record.quantity = random.int(in: 1...3)
            record.status = random.int(in: 1...4) == 1 ? .wasted : .used
            record.finishedDate = finished
            record.addedDate = calendar.date(byAdding: .day, value: -random.int(in: 2...10), to: finished) ?? finished
            records.append(record)
        }
        // A rescue streak: something used on each of the last 5 days.
        for day in 0..<5 {
            let preset = presets[random.int(in: 0...(presets.count - 1))]
            var record = makeItem(from: preset, expiresIn: 0)
            record.quantity = 1
            record.status = .used
            record.finishedDate = calendar.date(byAdding: .hour, value: 12, to: date(-day))
            records.append(record)
        }

        undoable("Loaded \(items.count) items and \(records.count) history records") {
            foodItems = items
            history = records
        }
    }

    /// Empties the fridge and history (Undo is available for a few seconds).
    func clearAllData() {
        undoable("Cleared fridge and history") {
            foodItems.forEach { ExpirationNotificationService.shared.cancel(for: $0) }
            foodItems = []
            history = []
        }
    }
}

/// Small repeatable random generator (same seed → same data every time).
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        var x = state
        x ^= x >> 33
        x = x &* 0xff51afd7ed558ccd
        x ^= x >> 33
        return x
    }

    mutating func int(in range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(next() % span)
    }

    mutating func shuffle<T>(_ array: inout [T]) {
        guard array.count > 1 else { return }
        for i in stride(from: array.count - 1, to: 0, by: -1) {
            array.swapAt(i, int(in: 0...i))
        }
    }
}
