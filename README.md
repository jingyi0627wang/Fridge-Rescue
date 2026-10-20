# Freshlings

Freshlings is a gamified iOS food-waste app that turns every item in your fridge into a "Freshling" whose HP bar drops as its expiration date gets closer.

Users add food by typing, choosing from a built-in ingredient list, picking a recent purchase, or scanning a barcode or produce PLU sticker. The app then suggests an expiration date and sends a 9 AM reminder before the food expires. The Fridge tab sorts food into shelves by urgency, and the Today tab lists what needs to be used first.

Marking food as eaten ("rescued") earns XP, levels, streaks and badges, and adds to running totals of money saved and CO₂ avoided. Users can also set weekly or monthly goals and review six-week charts and a full history.

The Recipes tab recommends dishes that use the most urgent ingredients. Pressing "I Cooked This" removes the right quantities from the fridge in one step, and users can write and save their own recipes.

## Data sources

- **Firebase Authentication** handles cross-device username/password login.
- A **bundled dataset of 175 ingredients** stores shelf life, typical price, storage tips and per-unit carbon footprints. The carbon footprints are derived from Poore & Nemecek (2018) via Our World in Data.
- **TheMealDB API** provides recipe recommendations and search, combined with a built-in recipe book.
- **Open Food Facts API** handles barcode lookups. Produce stickers are matched against a local PLU code table.
- The user's fridge, history and recipes are stored **locally on the device** (UserDefaults and on-device photo files).
- Reminders are scheduled with Apple's **UserNotifications** framework.

## Links

| | |
|---|---|
| 🎨 UI design & Design system | [link](https://www.figma.com/design/MgkEToHUGPU4CxeXIOzCj8/iOS-UI-design?node-id=0-1&t=qoRGb6T5FBaHzNDU-1) |
| 📱 Lo-fi interactive prototype | [link](https://claude.ai/artifact/LSQKHMsgSD5fYXnRaPyYqM#page-dcb81aee8d83) |
| 📊 Concept Presentation slides | [link](https://docs.google.com/presentation/d/1MnbRuoIEveXgX2Cipk-PD_ZLzLAE70H_JIFTv97B07M/edit?usp=sharing) |
| 📊 Final Presentation slides | [link](https://www.figma.com/deck/5DdTCYNDYXkvVKxmRY8qLs) |

## Contributions

### Jingyi
- **MainPages Development:** Built the initial Fridge, Today, and Recipes pages from scratch using SwiftUI, including their UI layouts, navigation, and core interactions.
- **Feature Enhancements:** Added a Settings section to the Fridge page, including language-switching functionality.
- **Navigation & Interaction Optimization:** Standardized page transitions and improved the smoothness and consistency of horizontal swipe gestures across the app.
- **Firebase Authentication:** Implemented user authentication and login functionality using Firebase Authentication.

### Gladys
- Add Food page: manual entry and autofill from the ingredient list
- Expiration date step: suggested date, storage tip, adjust before saving
- Food scanner: barcode lookup (Open Food Facts API) and produce sticker codes
- Recipe search, My Recipes (with photo upload) and Community feed
- UI/UX: game features (XP, levels, quests, badges), food pictures, and helping refine the app's look
- Fixes: reminder settings, expired food on Today, Log Out, Impact counts
- Feedback changes (v6.4): simpler Add page, food photos, Today + Impact merged, shorter recipe page

### Yitong
- **Data model and local storage:** structured food information and saved inventory between app sessions.
- **Expiration and HP logic:** calculated remaining shelf life, freshness states, and HP values.
- **Food Library:** added 143 common vegetables with shelf-life estimates, storage tips, and search.
- **Food matching:** improved ingredient matching and autofill accuracy.
- **Icons and notifications:** created and replaced all app icons and implemented expiration reminders.
- **Optimization:** fixed display issues, improved performance, and limited food animations to two shakes.

### Rumik
- Built the first login and sign-up flow (local Keychain version), later replaced by Firebase.
- Built the Impact page: money saved, CO₂ avoided (Poore & Nemecek 2018), used vs. wasted counts, and three goal types.
- Improved the HP calculation and partial use of stacked items.
- Added TheMealDB online recipes with an offline fallback, recipe categories, and a link from Today to Recipes.
- Added Quick Add and made long fridge lists condense.
- Merged all four members' code and fixed the build errors, with help from Claude AI.
- Created the Freshlings design system and applied it across the app.
- Designed the title page and the Recipes onboarding illustration.
- Made the workflow map, function summary, and lo-fi prototype.

## Progress

Each commit in this repository is one stage of the project. See the commit history for what changed at each step.
