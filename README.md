# DearBella 🎬

A native iOS app — a cinematic, mood-based movie recommender.

**The flow:** open the app → pick your mood → pick/refine genre → get
AI-generated personalized film recommendations. Plus a home feed with curated
picks, a "What should I watch tonight?" chat, and browse-by-vibe.

The design is dark-themed, image-heavy, with rounded poster cards.

---

## Tech

- **SwiftUI** (iOS 17+), iPhone-only, portrait.
- Pure Xcode project (no third-party package managers yet).
- Movie data via the **TMDB API** (added in a later step).
- AI recommendations + chat (added in a later step).

## Project structure

```
DearBella.xcodeproj      ← open this in Xcode
DearBella/
├── App/                 ← app entry point (DearBellaApp.swift)
├── Views/               ← screens & UI
├── Resources/           ← Theme, asset catalog (colors, app icon)
├── Models/              ← data types (added with TMDB)
└── Services/            ← networking / AI (added with TMDB + AI)
```

> The project uses Xcode's **synchronized folders**: any Swift file added
> inside `DearBella/` is picked up automatically — no need to manually
> register files in the project.

## Running it

1. Open `DearBella.xcodeproj` in Xcode 16 or newer.
2. Select an iPhone simulator (e.g. iPhone 15) in the toolbar.
3. Press **Run** (▶) or `Cmd+R`.

To run on a physical device you'll need to set your signing **Team** under
*Target → Signing & Capabilities* (see notes from the build session).

## Build plan

1. ✅ **Scaffold** — project opens & runs (this commit).
2. ⬜ **Onboarding** — splash → select genres → select top 5 films → "Great picks!".
3. ⬜ **Home feed** — curated cards, vibe pills, "Things to do" grid.
4. ⬜ **TMDB data** — real movies, posters, search.
5. ⬜ **AI** — recommendation logic + "What should I watch tonight?" chat.

## Secrets

API keys (TMDB, AI) are **never** committed. They go in a local
`Secrets.xcconfig` (already in `.gitignore`). Setup instructions added in
Step 4.
