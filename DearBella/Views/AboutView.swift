import SwiftUI

/// About / settings screen: hidden-film management, TMDB attribution
/// (required), a Privacy Policy link, and the app version. Presented as a
/// sheet from the Home header.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hidden: HiddenFilmsStore
    @EnvironmentObject private var notifications: NotificationService
    @EnvironmentObject private var watchlist: WatchlistStore
    @EnvironmentObject private var onboarding: OnboardingStore
    @State private var showClearConfirm = false
    @State private var showRedoConfirm = false

    private let privacyURL = URL(string: "https://dearbella-site.vercel.app")!

    private var appVersion: String? {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String
        let build = info?["CFBundleVersion"] as? String
        switch (short, build) {
        case let (v?, b?): return "\(v) (\(b))"
        case let (v?, nil): return v
        default: return nil
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    remindersSection
                    Divider().background(Theme.cream.opacity(0.12))
                    hiddenFilmsSection
                    Divider().background(Theme.cream.opacity(0.12))
                    tastePicksSection
                    Divider().background(Theme.cream.opacity(0.12))
                    clearListSection
                    Divider().background(Theme.cream.opacity(0.12))
                    tmdbAttribution
                    Divider().background(Theme.cream.opacity(0.12))
                    feedbackRow
                    privacyRow
                    if let appVersion {
                        Text("Version \(appVersion)")
                            .font(.dearBellaCaption)
                            .foregroundStyle(Theme.cream.opacity(0.5))
                            .padding(.top, 8)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("About")
                .font(.dmSerif(32))
                .foregroundStyle(Theme.cream)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.cream.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }

    /// Reminders can be turned off here rather than only in iOS Settings —
    /// a weekly nudge people can't stop from inside the app is how an app
    /// gets its notifications revoked wholesale.
    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: reminderBinding) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Friday & Saturday reminders")
                        .font(.dearBellaBody)
                        .foregroundStyle(Theme.cream)
                    Text("A pick waiting at 6:30, when you're actually deciding.")
                        .font(.dearBellaCaption)
                        .foregroundStyle(Theme.cream.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(Theme.highlight)

            if notifications.authorization == .denied {
                Text("Notifications are turned off for Dear Bella in iOS Settings.")
                    .font(.dearBellaCaption)
                    .foregroundStyle(Theme.accent.opacity(0.9))
            }
        }
        .task { await notifications.refreshAuthorization() }
    }

    /// Reflects the real system state, so the toggle can't claim reminders are
    /// on when iOS has denied them.
    private var reminderBinding: Binding<Bool> {
        Binding(
            get: { notifications.isEnabled },
            set: { wantsOn in
                Task {
                    if wantsOn {
                        await notifications.enable()
                    } else {
                        notifications.disable()
                    }
                }
            }
        )
    }

    /// Lets the user take back a "don't suggest this again" — without this the
    /// hide action would be a one-way door.
    @ViewBuilder
    private var hiddenFilmsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Hidden films")
                    .font(.dmSerif(22, relativeTo: .title3))
                    .foregroundStyle(Theme.cream)
                Spacer()
                if !hidden.isEmpty {
                    Button("Unhide all") { hidden.unhideAll() }
                        .font(.inter(13, weight: .medium))
                        .foregroundStyle(Theme.highlight)
                }
            }

            if hidden.isEmpty {
                Text("Films you tell Bella to stop suggesting will show up here, so you can bring them back.")
                    .font(.dearBellaCaption)
                    .foregroundStyle(Theme.cream.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(hidden.films) { film in
                    HStack(spacing: 12) {
                        Text(film.displayTitle)
                            .font(.dearBellaBody)
                            .foregroundStyle(Theme.cream)
                            .lineLimit(2)
                        Spacer(minLength: 8)
                        Button("Unhide") { hidden.unhide(film) }
                            .font(.inter(13, weight: .semibold))
                            .foregroundStyle(Theme.highlight)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    /// Taste changes, and the genres and five films someone chose on day one
    /// stop describing them. This runs those two screens again without
    /// touching anything they've saved since.
    private var tastePicksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                showRedoConfirm = true
            } label: {
                HStack {
                    Text("Redo my taste picks")
                        .font(.dearBellaBody)
                        .foregroundStyle(Theme.cream)
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.highlight)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text("Choose your genres and top five films again. Your list, ratings and notes stay exactly as they are.")
                .font(.dearBellaCaption)
                .foregroundStyle(Theme.cream.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
        .confirmationDialog(
            "Redo your taste picks?",
            isPresented: $showRedoConfirm,
            titleVisibility: .visible
        ) {
            Button("Start again") {
                dismiss()
                onboarding.resetOnboarding()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll go back through choosing genres and your top five. Nothing in your list is affected.")
        }
    }

    /// A way to start over. Hidden when the list is already empty, so it isn't
    /// a permanently armed destructive button on a settings screen.
    @ViewBuilder
    private var clearListSection: some View {
        if !watchlist.films.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    Label("Clear my list", systemImage: "trash")
                        .font(.dearBellaBody)
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)

                Text("Removes all \(watchlist.films.count) films, along with your ratings and notes.")
                    .font(.dearBellaCaption)
                    .foregroundStyle(Theme.cream.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .confirmationDialog(
                "Clear your whole list?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Clear everything", role: .destructive) { watchlist.removeAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All \(watchlist.films.count) films go, and so do the ratings and notes on them. This can't be undone.")
            }
        }
    }

    /// Required TMDB attribution: logo + the exact attribution sentence.
    private var tmdbAttribution: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image("tmdb_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120)

            Text("This product uses the TMDB API but is not endorsed or certified by TMDB.")
                .font(.dearBellaBody)
                .foregroundStyle(Theme.cream)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Hidden entirely until a Tally form URL is set in `ExternalLinks`, so
    /// there's never a link here that goes nowhere.
    @ViewBuilder
    private var feedbackRow: some View {
        if let url = ExternalLinks.feedbackForm(source: "ios-about") {
            VStack(alignment: .leading, spacing: 8) {
                Link(destination: url) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Share your feedback")
                                .font(.dearBellaBody)
                                .foregroundStyle(Theme.cream)
                            Text("Two minutes, and it shapes what gets built next.")
                                .font(.dearBellaCaption)
                                .foregroundStyle(Theme.cream.opacity(0.6))
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "arrow.up.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.highlight)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var privacyRow: some View {
        Link(destination: privacyURL) {
            HStack {
                Text("Privacy Policy")
                    .font(.dearBellaBody)
                    .foregroundStyle(Theme.cream)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.highlight)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AboutView()
        .environmentObject(HiddenFilmsStore.shared)
        .environmentObject(NotificationService.shared)
        .environmentObject(WatchlistStore())
        .environmentObject(OnboardingStore())
}
