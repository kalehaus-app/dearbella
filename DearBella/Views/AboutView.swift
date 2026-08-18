import SwiftUI

/// About / settings screen: hidden-film management, TMDB attribution
/// (required), a Privacy Policy link, and the app version. Presented as a
/// sheet from the Home header.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hidden: HiddenFilmsStore

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
                    hiddenFilmsSection
                    Divider().background(Theme.cream.opacity(0.12))
                    tmdbAttribution
                    Divider().background(Theme.cream.opacity(0.12))
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
                        .foregroundStyle(Theme.cyan)
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
                            .foregroundStyle(Theme.cyan)
                    }
                    .padding(.vertical, 4)
                }
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

    private var privacyRow: some View {
        Link(destination: privacyURL) {
            HStack {
                Text("Privacy Policy")
                    .font(.dearBellaBody)
                    .foregroundStyle(Theme.cream)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.cyan)
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
}
