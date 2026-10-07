//
//  ExpirationConfirmView.swift
//  Member 2 – Add Food
//
//  Shows the suggested expiration date (from ingredients_preset.json),
//  lets the user adjust it, then saves with store.addItem(...).
//

import SwiftUI
import UIKit

struct ExpirationConfirmView: View {
    let draft: FoodDraft
    @ObservedObject var store: FoodStore
    let onSaved: () -> Void

    @State private var expirationDate: Date
    private let suggestedDate: Date

    init(draft: FoodDraft, store: FoodStore, onSaved: @escaping () -> Void) {
        self.draft = draft
        self.store = store
        self.onSaved = onSaved

        let start = Calendar.current.startOfDay(for: draft.addedDate)
        let date = Calendar.current.date(byAdding: .day, value: draft.shelfLifeDays, to: start) ?? start
        suggestedDate = date
        _expirationDate = State(initialValue: date)
    }

    /// Days from today until the chosen date (negative = already expired)
    private var daysLeft: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day],
                                       from: calendar.startOfDay(for: .now),
                                       to: calendar.startOfDay(for: expirationDate)).day ?? 0
    }

    var body: some View {
        Form {
            Section { summaryRow }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Label(suggestedDate.formatted(date: .abbreviated, time: .omitted),
                          systemImage: "sparkles")
                        .font(.headline)
                    Text("Usually lasts about \(dayText(draft.shelfLifeDays)).")
                        .foregroundStyle(.secondary)
                    if let tip = draft.preset?.storageTip, !tip.isEmpty {
                        Label(tip, systemImage: "lightbulb")
                            .font(.subheadline)
                            .padding(.top, 4)
                    }
                }
            } header: {
                Text("Suggested Expiration")
            } footer: {
                Text("This is an estimate. If the package has a printed date, use that instead.")
            }

            Section("Confirm Date") {
                DatePicker("Expires on",
                           selection: $expirationDate,
                           in: Calendar.current.startOfDay(for: draft.addedDate)...,
                           displayedComponents: .date)
                    .datePickerStyle(.graphical)

                HStack {
                    Button("+1 day") { addDays(1) }
                    Button("+1 week") { addDays(7) }
                    Spacer()
                    Button("Reset") { expirationDate = suggestedDate }
                        .disabled(Calendar.current.isDate(expirationDate, inSameDayAs: suggestedDate))
                }
                .buttonStyle(.bordered)

                statusRow
            }
        }
        .navigationTitle("Expiration Date")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(action: save) {
                Text("Add to Fridge").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
    }

    // MARK: - Pieces

    private var summaryRow: some View {
        HStack(spacing: 12) {
            if let photo = draft.photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Text(draft.category.addFoodIcon)
                    .font(.largeTitle)
                    .frame(width: 60, height: 60)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(draft.name).font(.headline)
                Text("Qty \(draft.quantity) · \(draft.category.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if draft.recognizedFromPhoto {
                    Label("Recognized from photo", systemImage: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.purple)
                }
            }
        }
    }

    @ViewBuilder
    private var statusRow: some View {
        if daysLeft < 0 {
            Label("Already expired \(dayText(-daysLeft)) ago", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        } else if daysLeft == 0 {
            Label("Expires today", systemImage: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
        } else if daysLeft <= 2 {
            Label("Expires in \(dayText(daysLeft)) — eat it soon!", systemImage: "clock.fill")
                .foregroundStyle(.orange)
        } else {
            Label("Expires in \(dayText(daysLeft))", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }

    // MARK: - Actions

    private func addDays(_ days: Int) {
        expirationDate = Calendar.current.date(byAdding: .day, value: days, to: expirationDate) ?? expirationDate
    }

    private func save() {
        let item = FoodItem(
            name: draft.name,
            category: draft.category,
            addedDate: draft.addedDate,
            expirationDate: Calendar.current.startOfDay(for: expirationDate),
            quantity: draft.quantity,
            estimatedValue: draft.estimatedValue,
            carbonFactor: draft.carbonFactor
        )
        store.addItem(item)   // FoodStore saves it automatically
        onSaved()
    }

    private func dayText(_ n: Int) -> String {
        n == 1 ? "1 day" : "\(n) days"
    }
}

#Preview {
    NavigationStack {
        ExpirationConfirmView(
            draft: FoodDraft(name: "Carrot", category: .vegetable, quantity: 3,
                             addedDate: .now, estimatedValue: 1.50, preset: nil,
                             photo: nil, recognizedFromPhoto: true),
            store: FoodStore()
        ) {}
    }
}
