import SwiftUI

/// A gym-friendly number control: big − / + buttons with a tappable value in between
/// (tap the value to type an exact number).
struct NumberStepper: View {
    let label: String
    @Binding var value: Double?
    let step: Double
    var allowsDecimals = false

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Button { adjust(by: -step) } label: {
                    Image(systemName: "minus").frame(width: 24, height: 24)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Decrease \(label)")

                TextField("–", value: $value, format: .number.precision(.fractionLength(0...(allowsDecimals ? 1 : 0))))
                    .keyboardType(allowsDecimals ? .decimalPad : .numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title3.monospacedDigit().bold())
                    .frame(minWidth: 52)
                    .accessibilityLabel(label)

                Button { adjust(by: step) } label: {
                    Image(systemName: "plus").frame(width: 24, height: 24)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Increase \(label)")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func adjust(by delta: Double) {
        value = max(0, (value ?? 0) + delta)
    }
}

extension Binding where Value == Int? {
    /// Lets an optional whole-number value drive a `NumberStepper`.
    var asDouble: Binding<Double?> {
        Binding<Double?>(
            get: { wrappedValue.map(Double.init) },
            set: { wrappedValue = $0.map { Int($0.rounded()) } }
        )
    }
}
