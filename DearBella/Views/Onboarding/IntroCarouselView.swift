import SwiftUI

/// One slide's content: a headline and a feature mock graphic.
private struct IntroSlide: Identifiable {
    let id = UUID()
    let title: String
    let kind: Kind
    enum Kind { case chat, curated, vibe }

    static let all: [IntroSlide] = [
        IntroSlide(title: "Always know\nwhat to watch", kind: .chat),
        IntroSlide(title: "Personalized like\na friend who\nknows cinema.", kind: .curated),
        IntroSlide(title: "Your cinematic\ncompanion", kind: .vibe),
    ]
}

private struct IntroSlideView: View {
    let slide: IntroSlide

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text(slide.title)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            switch slide.kind {
            case .chat: ChatMock()
            case .curated: CuratedMock()
            case .vibe: VibeMock()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }
}

/// The swipeable 3-slide intro (wireframe Frames 53–55).
///
/// "Get Started" advances through the slides; on the last slide it calls
/// `onFinished`, which moves the flow on to genre selection.
struct IntroCarouselView: View {
    let onFinished: () -> Void

    @State private var page = 0
    private let slides = IntroSlide.all

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $page) {
                ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                    IntroSlideView(slide: slide)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            PageDots(count: slides.count, activeIndex: page)

            PrimaryButton(title: "Get Started", action: advance)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
        .background(Theme.background.ignoresSafeArea())
    }

    private func advance() {
        if page < slides.count - 1 {
            withAnimation { page += 1 }
        } else {
            onFinished()
        }
    }
}

#Preview {
    IntroCarouselView(onFinished: {})
}
