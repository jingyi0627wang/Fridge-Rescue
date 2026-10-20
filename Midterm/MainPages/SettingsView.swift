
import SwiftUI

// MARK: - Freshlings Settings

struct SettingsView: View {

    @ObservedObject var foodStore: FoodStore
    @Environment(\.dismiss) private var dismiss

    // MARK: - Saved Preferences

    @AppStorage("expirationRemindersEnabled")
    private var remindersEnabled = true

    @AppStorage("reminderDaysBefore")
    private var reminderDays = 3

    @AppStorage("appLanguage")
    private var appLanguage = "en"

    @State private var showClearConfirmation = false

    // MARK: - Freshlings Colors

    private let background = Color(
        red: 0.985,
        green: 0.992,
        blue: 0.970
    )

    private let darkGreen = Color(
        red: 0.22,
        green: 0.49,
        blue: 0.19
    )

    private let brown = Color(
        red: 0.34,
        green: 0.27,
        blue: 0.22
    )

    private let softGreen = Color(
        red: 0.931,
        green: 0.976,
        blue: 0.869
    )

    // MARK: - Main View

    var body: some View {

        Form {

            // MARK: App Header

            Section {

                HStack(spacing: 12) {

                    Image("FreshlingsCharacter")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .frame(width: 48, height: 48)
                        .background(softGreen, in: Circle())

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text("Freshlings")
                            .font(
                                .system(
                                    size: 21,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(brown)

                        Text("Make your fridge work for you.")
                            .font(.subheadline)
                            .foregroundStyle(
                                brown.opacity(0.8)
                            )
                    }
                }
                .padding(.vertical, 5)
            }

            // MARK: Language

            Section {

                Picker(
                    "App Language",
                    selection: $appLanguage
                ) {

                    Text("English")
                        .tag("en")

                    Text("简体中文")
                        .tag("zh-Hans")
                }
                .pickerStyle(.menu)

            } header: {

                Text("Language / 语言")
            } footer: {

                Text(
                    "Choose the language used in Freshlings."
                )
            }

            // MARK: Reminder Preferences

            Section {

                Toggle(
                    "Expiration reminders",
                    isOn: $remindersEnabled
                )

                Picker(
                    "Remind me before",
                    selection: $reminderDays
                ) {

                    Text("1 day").tag(1)
                    Text("2 days").tag(2)
                    Text("3 days").tag(3)
                    Text("5 days").tag(5)
                    Text("7 days").tag(7)
                }
                .disabled(!remindersEnabled)

            } header: {

                Text("Reminder preferences")

            } footer: {

                Text(
                    "Preferences are saved on this device. Notification scheduling is not yet connected to these settings."
                )
            }

            // MARK: My Data

            Section("My Data") {

                Label(
                    "Stored on this iPhone",
                    systemImage: "iphone"
                )

                Text(
                    "Food records are stored locally and do not automatically sync across devices. Removing this app may remove its local records."
                )
                .font(.footnote)
                .foregroundStyle(
                    brown.opacity(0.8)
                )
            }

            // MARK: Demo & Testing

            Section("Demo & Testing") {

                Button {

                    foodStore.addDemoItems()

                } label: {

                    Label(
                        "Load Demo Food (6)",
                        systemImage: "carrot"
                    )
                }

                Button {

                    foodStore.loadStressTestData()

                } label: {

                    Label(
                        "Load Lots of Food (60)",
                        systemImage: "square.stack.3d.up.fill"
                    )
                }

                Button(role: .destructive) {

                    showClearConfirmation = true

                } label: {

                    Label(
                        "Clear Fridge & History",
                        systemImage: "trash"
                    )
                }
            }

            // MARK: About

            Section("About") {

                Label(
                    "Freshlings",
                    systemImage: "info.circle"
                )

                Text(
                    "A friendly food-management app to help reduce food waste."
                )
                .font(.footnote)
                .foregroundStyle(
                    brown.opacity(0.8)
                )
            }
        }

        // MARK: Appearance

        .scrollContentBackground(.hidden)

        .background(
            background.ignoresSafeArea()
        )

        .tint(darkGreen)

        .navigationTitle("Settings")

        .navigationBarTitleDisplayMode(.inline)

        // MARK: Done Button

        .toolbar {

            ToolbarItem(
                placement: .topBarTrailing
            ) {

                Button("Done") {

                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }

        // MARK: Clear Confirmation

        .confirmationDialog(
            "Clear your fridge and history?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {

            Button(
                "Clear Fridge & History",
                role: .destructive
            ) {

                foodStore.clearAllData()
            }

            Button(
                "Cancel",
                role: .cancel
            ) { }

        } message: {

            Text(
                "This removes your stored food and history. This action cannot be undone."
            )
        }
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        SettingsView(
            foodStore: FoodStore()
        )
    }
}

