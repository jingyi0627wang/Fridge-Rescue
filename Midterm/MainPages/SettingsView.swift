
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

    @AppStorage("username")
    private var username = ""

    @AppStorage("isLoggedIn")
    private var isLoggedIn = false

    @State private var showClearConfirmation = false
    @State private var showLogOutConfirmation = false

    // MARK: - Main View

    var body: some View {

        Form {

            // MARK: App Header

            Section {

                HStack(spacing: 12) {

                    Image("FreshlingsCharacter")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                        .frame(width: 48, height: 48)
                        .background(Game.mint,
                                    in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text("Freshlings")
                            .font(.game(20, .bold))
                            .foregroundStyle(Game.orange)

                        Text("Make your fridge work for you.")
                            .font(.game(14, .medium))
                            .foregroundStyle(.secondary)
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

                if !remindersEnabled {
                    Text("Reminders are off. You can still check the Today tab.")
                } else if reminderDays == 1 {
                    Text("You'll get a reminder at 9 AM, 1 day before food expires.")
                } else {
                    Text("You'll get a reminder at 9 AM, \(reminderDays) days before food expires.")
                }
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
                .font(.game(13, .medium))
                .foregroundStyle(.secondary)
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

            // MARK: Account

            Section("Account") {

                if !username.isEmpty {

                    Label {
                        Text(username)
                    } icon: {
                        Image("IconProfile")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                    }
                }

                Button(role: .destructive) {

                    showLogOutConfirmation = true

                } label: {

                    Label(
                        "Log Out",
                        systemImage: "rectangle.portrait.and.arrow.right"
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
                .font(.game(13, .medium))
                .foregroundStyle(.secondary)
            }
        }

        // MARK: Appearance


        .font(.game(16, .medium))
        .foregroundStyle(Game.brown)
        .gameBackground()
        .tint(Game.greenDark)
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

        // MARK: Reminder changes → reschedule notifications

        .onChange(of: remindersEnabled) {
            rescheduleReminders()
        }

        .onChange(of: reminderDays) {
            rescheduleReminders()
        }

        // MARK: Log Out Confirmation

        .confirmationDialog(
            "Log out of Freshlings?",
            isPresented: $showLogOutConfirmation,
            titleVisibility: .visible
        ) {

            Button(
                "Log Out",
                role: .destructive
            ) {

                dismiss()
                isLoggedIn = false
            }

            Button(
                "Cancel",
                role: .cancel
            ) { }

        } message: {

            Text(
                "Your food stays saved on this phone. Log in again with the same username and password."
            )
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
                "This removes your stored food and history. You can undo it for a few seconds."
            )
        }
    }

    private func rescheduleReminders() {

        let items = foodStore.foodItems

        Task {
            await ExpirationNotificationService.shared
                .rescheduleAll(items: items)
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

