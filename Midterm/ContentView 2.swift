import SwiftUI

struct ContentView: View {
    @EnvironmentObject var foodStore: FoodStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if foodStore.foodItems.isEmpty {
                        ContentUnavailableView(
                            "No Food Yet",
                            systemImage: "carrot",
                            description: Text("Tap Add Demo Data to test the HP system.")
                        )
                        .padding(.top, 60)
                    } else {
                        ForEach(foodStore.foodItems) { item in
                            // 美化后的食物卡片设计
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(item.name)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(item.hpPercentage))% HP")
                                        .font(.headline)
                                        .fontWeight(.heavy)
                                        .foregroundStyle(item.freshnessLevel.color)
                                }

                                ProgressView(value: item.hpPercentage, total: 100)
                                    .tint(item.freshnessLevel.color)
                                    .scaleEffect(x: 1, y: 1.8, anchor: .center) // 加粗进度条
                                    .padding(.vertical, 4)

                                HStack {
                                    Text(item.freshnessLevel.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(item.freshnessLevel.color)
                                    
                                    Spacer()
                                    
                                    Text("\(item.remainingDays) days left")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("My Fridge 🥗")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .toolbar {
                Button("Add Demo Data") {
                    foodStore.addDemoItems()
                }
                .fontWeight(.bold)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FoodStore())
}
