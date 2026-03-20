import SwiftUI

/// Write a journal entry to unlock apps — must hit a minimum word count
struct JournalingView: View {
    let condition: UnlockCondition
    let onComplete: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var text = ""
    @FocusState private var isFocused: Bool

    private var targetWords: Int {
        condition.targetWordCount ?? 50
    }

    private var currentWordCount: Int {
        text.split(separator: " ", omittingEmptySubsequences: true).count
    }

    private var isComplete: Bool {
        currentWordCount >= targetWords
    }

    private var progress: Double {
        guard targetWords > 0 else { return 0 }
        return min(Double(currentWordCount) / Double(targetWords), 1.0)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Prompt
                if let prompt = condition.journalPrompt, !prompt.isEmpty {
                    Text(prompt)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 8)
                } else {
                    Text("Write what's on your mind. Be honest with yourself.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                // Text editor
                TextEditor(text: $text)
                    .focused($isFocused)
                    .font(.body)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                // Progress bar
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: isComplete ? [.green, .green] : [.purple, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * progress, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: progress)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("\(currentWordCount) / \(targetWords) words")
                            .font(.caption)
                            .foregroundColor(isComplete ? .green : .gray)

                        Spacer()

                        if isComplete {
                            Text("Done!")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal)

                // Submit button
                Button(action: {
                    onComplete()
                    dismiss()
                }) {
                    Text("Submit Entry")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isComplete ? Color.green : Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!isComplete)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { isFocused = true }
        }
    }
}
