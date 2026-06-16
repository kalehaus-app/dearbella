import SwiftUI

/// The "What should I watch tonight?" chat. The transcript scrolls above; the
/// bottom interaction area changes with the conversation phase (mood pills →
/// feeling pills → results controls / refine field).
struct ChatView: View {
    @EnvironmentObject private var watchlist: WatchlistStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: ChatViewModel
    @FocusState private var refineFocused: Bool

    init(context: TasteContext) {
        _vm = StateObject(wrappedValue: ChatViewModel(context: context))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                transcript
                inputArea
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Dear Bella")
                .font(.title3.bold())
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Transcript

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(vm.entries) { entry in
                        entryView(entry).id(entry.id)
                    }
                    if vm.isLoading {
                        thinkingRow.id("loading")
                    } else {
                        // Mood/feeling pills flow under the latest bubble (not
                        // pinned to the bottom), so short conversations don't
                        // leave a big empty gap.
                        switch vm.phase {
                        case .mood:
                            pillsRow(vm.moodOptions) { vm.pickMood($0) }
                        case .feeling:
                            pillsRow(vm.feelingOptions) { vm.pickFeeling($0) }
                        case .results, .refine:
                            EmptyView()
                        }
                    }
                }
                .padding(16)
            }
            .onChange(of: vm.entries.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: vm.isLoading) { _, _ in
                scrollToBottom(proxy)
            }
        }
    }

    @ViewBuilder
    private func entryView(_ entry: ChatViewModel.Entry) -> some View {
        switch entry.kind {
        case .bella(let text):
            BellaBubble(text: text)
        case .user(let text):
            UserBubble(text: text)
        case .picks(let films):
            VStack(spacing: 10) {
                ForEach(films) { PickCard(film: $0) }
            }
        }
    }

    private var thinkingRow: some View {
        HStack(spacing: 8) {
            ProgressView().tint(.white)
            Text("DearBella is thinking…")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation {
            if vm.isLoading {
                proxy.scrollTo("loading", anchor: .bottom)
            } else if let last = vm.entries.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    // MARK: - Input area

    @ViewBuilder
    private var inputArea: some View {
        if !vm.isLoading {
            switch vm.phase {
            case .refine:
                bottomBar { refineRow }
            case .results:
                if vm.hasResults { bottomBar { resultsControls } }
            case .mood, .feeling:
                // Pills now live in the scrollable transcript, so the bottom
                // bar renders nothing here (no empty strip).
                EmptyView()
            }
        }
    }

    private func bottomBar<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.background)
    }

    private func pillsRow(_ options: [String], action: @escaping (String) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    PillButton(title: option) { action(option) }
                }
            }
        }
    }

    private var resultsControls: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                PillButton(title: "Not feeling it") {
                    vm.askForReference()
                    refineFocused = true
                }
                PillButton(title: "More like these") {
                    vm.moreSuggestions()
                }
                PillButton(title: "Found it! 🎉") {
                    dismiss()
                }
            }
        }
    }

    private var refineRow: some View {
        HStack(spacing: 10) {
            TextField("e.g. movies like Mean Girls", text: $vm.referenceText)
                .foregroundStyle(.white)
                .tint(Theme.accent)
                .focused($refineFocused)
                .submitLabel(.send)
                .onSubmit { vm.submitReference() }
                .padding(12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                vm.submitReference()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(Theme.accent)
            }
        }
    }
}

#Preview {
    ChatView(context: TasteContext(genres: ["Horror", "Indie"], topFilms: ["Parasite", "Lady Bird"]))
        .environmentObject(WatchlistStore())
}
