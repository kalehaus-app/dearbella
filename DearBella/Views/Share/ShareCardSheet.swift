import SwiftUI
import UIKit

/// The presented screen for the monthly recap: shows a preview of the rendered
/// card and offers Share (ShareLink) and Save to Photos. Renders the 1080×1920
/// image once on appear.
struct ShareCardSheet: View {
    let films: [String]

    @Environment(\.dismiss) private var dismiss
    @State private var rendered: UIImage?
    @State private var saveMessage: String?

    private var previewTitle: String { "My \(ShareCardData.monthName.capitalized), in films" }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                header
                preview
                actions
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .onAppear {
            if rendered == nil { rendered = ShareCardRenderer.render(films: films) }
        }
    }

    private var header: some View {
        HStack {
            Text("Your month, in films")
                .font(.dearBellaSectionHeader)
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

    @ViewBuilder
    private var preview: some View {
        if let rendered {
            Image(uiImage: rendered)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .frame(maxHeight: .infinity)
        } else {
            ProgressView().tint(Theme.highlight)
                .frame(maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var actions: some View {
        if let rendered {
            VStack(spacing: 12) {
                ShareLink(
                    item: Image(uiImage: rendered),
                    preview: SharePreview(previewTitle, image: Image(uiImage: rendered))
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.dearBellaButton)
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.highlight)
                        .clipShape(Capsule())
                }

                Button { saveToPhotos(rendered) } label: {
                    Label("Save to Photos", systemImage: "arrow.down.to.line")
                        .font(.dearBellaButton)
                        .foregroundStyle(Theme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Theme.cream.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)

                if let saveMessage {
                    Text(saveMessage)
                        .font(.dearBellaCaption)
                        .foregroundStyle(Theme.cream.opacity(0.7))
                }
            }
        }
    }

    private func saveToPhotos(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        withAnimation { saveMessage = "Saved to Photos ✓" }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation { saveMessage = nil }
        }
    }
}

#Preview {
    ShareCardSheet(films: ["Aftersun", "Past Lives", "Moonlight", "Lady Bird", "The Worst Person in the World"])
}
