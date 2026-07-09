import SwiftUI

struct TimingSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("SmartSlides")
                .font(.system(size: 22, weight: .bold))

            VStack(alignment: .leading, spacing: 12) {
                Text("Timing")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                sliderRow(
                    title: "Display Duration",
                    value: Binding(
                        get: { viewModel.settings.displayDuration },
                        set: { viewModel.updateDisplayDuration($0) }
                    ),
                    range: 2...20,
                    unit: "sec"
                )

                sliderRow(
                    title: "Transition Duration",
                    value: Binding(
                        get: { viewModel.settings.transitionDuration },
                        set: { viewModel.updateTransitionDuration($0) }
                    ),
                    range: 0.2...5,
                    unit: "sec"
                )
                .opacity(viewModel.settings.crossfadeEnabled ? 1 : 0.4)
                .disabled(!viewModel.settings.crossfadeEnabled)

                Toggle("Crossfade Transition", isOn: Binding(
                    get: { viewModel.settings.crossfadeEnabled },
                    set: { viewModel.updateCrossfadeEnabled($0) }
                ))
                .toggleStyle(.switch)

                Text(viewModel.settings.crossfadeEnabled
                     ? "Slides dissolve into each other over the transition duration."
                     : "Slides switch instantly, no fade.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Order / Hash")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Seed")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%016X", viewModel.settings.seed))
                        .font(.system(.caption, design: .monospaced))
                }

                Button("Generate New Hash") {
                    viewModel.generateNewHash()
                }

                Divider()

                Toggle("Rehash on Replay", isOn: Binding(
                    get: { viewModel.settings.rehashOnReplay },
                    set: { viewModel.toggleRehashOnReplay($0) }
                ))
                .toggleStyle(.switch)

                Text("Shortly before the timeline ends, generates a fresh shuffle to continue into — a never-ending slideshow. You can still scrub back into the one it replaced.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Reset to Current Hash") {
                    viewModel.resetToCurrentHash()
                }
                .disabled(viewModel.settings.previousTimeline.isEmpty)
            }

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 340, maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: "%.1f %@", value.wrappedValue, unit))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .font(.system(size: 12))
            Slider(value: value, in: range)
        }
    }
}
