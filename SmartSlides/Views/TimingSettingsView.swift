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
