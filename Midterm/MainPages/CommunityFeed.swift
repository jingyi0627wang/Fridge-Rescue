import SwiftUI
import Symbols

// MARK: - Community feed (inside the Recipes tab)
// Weekly challenge on top, then shared recipes: the user's own shared recipes
// first, then SAMPLE posts (marked "Sample"). Like ♥ and Save are kept on the
// phone. Real sharing between phones would need an online server.

struct CommunityFeed: View {
    let searchText: String

    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var myRecipes: MyRecipeStore
    @AppStorage("username") private var username = ""

    /// The user's shared recipes as posts, then the sample posts.
    private var posts: [CommunityPost] {
        let mine: [CommunityPost] = myRecipes.sharedRecipes.map { recipe in
            CommunityPost(
                id: "mine-post-\(recipe.id.uuidString)",
                author: recipe.author.isEmpty ? (username.isEmpty ? "You" : username) : recipe.author,
                authorColor: Game.green,
                recipe: recipe.asRecipe,
                caption: "",
                baseLikes: 0,
                date: recipe.createdAt,
                isSample: false
            )
        }
        let all = mine + CommunityData.samplePosts
        guard !searchText.isEmpty else { return all }
        let lowered = searchText.lowercased()
        return all.filter { post in
            post.recipe.name.lowercased().contains(lowered) ||
            post.author.lowercased().contains(lowered) ||
            post.recipe.ingredients.contains { $0.lowercased().contains(lowered) }
        }
    }

    var body: some View {
        let shown = posts

        VStack(alignment: .leading, spacing: 12) {
            if searchText.isEmpty {
                challengeCard
            }

            GameSectionHeader(title: "Shared Recipes", count: shown.count)

            if shown.isEmpty {
                Text("No posts match that search.")
                    .font(.game(15, .medium))
                    .foregroundStyle(Game.brownSoft)
                    .frame(maxWidth: .infinity)
                    .gameCard(padding: 20)
            }

            LazyVStack(spacing: 14) {
                ForEach(shown) { post in
                    PostCard(post: post)
                }
            }

            Label("Sample posts are examples for this demo. Sharing between phones needs an online account system.",
                  systemImage: "info.circle")
                .font(.game(12, .medium))
                .foregroundStyle(Game.brownSoft)
                .padding(.horizontal, 4)
                .padding(.top, 4)
        }
    }

    // MARK: - Weekly challenge

    private var challengeCard: some View {
        let challenge = CommunityData.currentChallenge
        let progress = min(foodStore.challengeProgress(challenge), 1)

        return HStack(spacing: 14) {
            FreshSymbol(symbol: FoodIcon.symbol(forEmoji: challenge.emoji), size: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(challenge.title))
                    .font(.game(18, .bold))
                    .foregroundStyle(Game.brown)
                Text(LocalizedStringKey(challenge.detail))
                    .font(.ui(13))
                    .foregroundStyle(Game.brownSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text(progress >= 1 ? "Done this week" : "This week's challenge")
                    .font(.ui(12, .semibold))
                    .foregroundStyle(progress >= 1 ? Game.greenInk : Game.orangeDark)
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)

            ZStack {
                Circle().stroke(Game.orange.opacity(0.25), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(Game.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                if progress >= 1 {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Game.orangeDark)
                } else {
                    Text("0/1")
                        .font(.ui(12, .semibold))
                        .foregroundStyle(Game.brown)
                }
            }
            .frame(width: 44, height: 44)
        }
        .gameCard(padding: 16, fill: Game.orangeSoft)
    }
}

// MARK: - Post card

private struct PostCard: View {
    let post: CommunityPost

    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var myRecipes: MyRecipeStore

    var body: some View {
        let liked = myRecipes.isLiked(post.id)
        let saved = myRecipes.hasRecipe(named: post.recipe.name)
        let rescued = Array(post.recipe.items.prefix(4))

        VStack(alignment: .leading, spacing: 10) {
            // Author
            HStack(spacing: 10) {
                FreshlingMascot(size: 26, color: post.authorColor)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(post.authorColor.opacity(0.18)))
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: post.author)
                        .font(.ui(14, .semibold))
                        .foregroundStyle(Game.brown)
                    Text(post.date, format: .relative(presentation: .named))
                        .font(.game(12, .medium))
                        .foregroundStyle(Game.brownSoft)
                }
                Spacer()
                if post.isSample {
                    Text("Sample")
                        .font(.game(11, .bold))
                        .foregroundStyle(Game.brownSoft)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Game.track))
                } else {
                    Text("You")
                        .font(.game(11, .bold))
                        .foregroundStyle(Game.greenInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Game.mint))
                }
            }

            // Photo / dish
            NavigationLink {
                RecipeDetailView(
                    recipe: post.recipe,
                    focusIngredient: RecipeData.rescueItem(for: post.recipe, in: foodStore.foodItems)
                )
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        if let url = post.recipe.imageURL {
                            RecipePhoto(url: url) { dishPlaceholder }
                        } else {
                            dishPlaceholder
                        }
                    }
                    .frame(height: 190)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text(post.recipe.name)
                        .font(.game(19, .bold))
                        .foregroundStyle(Game.brown)
                        .multilineTextAlignment(.leading)

                    if !post.caption.isEmpty {
                        Text(verbatim: post.caption)
                            .font(.game(14, .medium))
                            .foregroundStyle(Game.brown.opacity(0.85))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 6) {
                        Text("Rescues")
                            .font(.game(12, .semibold))
                            .foregroundStyle(Game.brownSoft)
                        ForEach(rescued, id: \.self) { ingredient in
                            FoodIconView(name: ingredient.name, size: 19)
                                .padding(3)
                                .background(Circle().fill(Game.mint))
                        }
                        Spacer(minLength: 4)
                        Label("\(post.recipe.time) min", systemImage: "clock")
                            .font(.game(12, .semibold))
                            .foregroundStyle(Game.brownSoft)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            DashedDivider()
                .padding(.horizontal, -14)

            // Actions
            HStack(spacing: 18) {
                Button {
                    withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                        myRecipes.toggleLike(post.id)
                    }
                } label: {
                    Label("\(post.baseLikes + (liked ? 1 : 0))",
                          systemImage: liked ? "heart.fill" : "heart")
                        .foregroundStyle(liked ? Game.red : Game.brownSoft)
                        .symbolEffect(.bounce, value: liked)
                }
                .accessibilityLabel(liked ? "Unlike" : "Like")

                if post.isSample {
                    Button {
                        myRecipes.saveCopy(of: post.recipe, author: post.author)
                        FreshlingsHaptics.success()
                    } label: {
                        Label(saved ? "Saved" : "Save",
                              systemImage: saved ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(saved ? Game.greenInk : Game.brownSoft)
                    }
                    .disabled(saved)
                }

                Spacer()

                ShareLink(item: "\(post.recipe.name) — a food-rescue recipe on Freshlings") {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Game.brownSoft)
                }
                .accessibilityLabel("Share")
            }
            .font(.ui(14, .semibold))
            .buttonStyle(.plain)
        }
        .gameCard(padding: 14)
    }

    private var dishPlaceholder: some View {
        ZStack {
            LinearGradient(colors: [post.authorColor.opacity(0.25), Game.cream],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            FreshSymbol(symbol: FoodIcon.symbol(forEmoji: post.recipe.emoji), size: 92)
        }
    }
}
