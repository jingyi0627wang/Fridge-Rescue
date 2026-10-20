import SwiftUI

struct RecipeIconPicker: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(RecipeIcon.choices) { choice in
                        let selected = RecipeIcon.symbol(for: selection) == choice.id
                        Button {
                            selection = choice.id
                            dismiss()
                        } label: {
                            VStack(spacing: 8) {
                                FreshSymbol(symbol: choice.id, size: 68)
                                Text(choice.title)
                                    .font(.game(14, .semibold))
                                    .foregroundStyle(Game.brown)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(minHeight: 36)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selected ? Game.mint : Color.white,
                                        in: RoundedRectangle(cornerRadius: 18))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(selected ? Game.greenDark : Color.clear, lineWidth: 2)
                            }
                            .overlay(alignment: .topTrailing) {
                                if selected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Game.greenDark)
                                        .padding(8)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(choice.title)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                .padding(16)
            }
            .gameBackground()
            .navigationTitle("Recipe Illustration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
