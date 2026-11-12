import SwiftUI

/// One large, tappable checklist row. The whole row toggles the item.
struct KitItemRow: View {
    let item: KitItem
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(isChecked ? Theme.ok : Theme.textPrimary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                        .strikethrough(isChecked, color: Theme.textSecondary)
                    Text(item.detail)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(isChecked ? Theme.ok : Theme.surfaceBorder, lineWidth: Theme.borderWidth)
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isChecked)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.title). \(item.detail)")
        .accessibilityValue(isChecked ? String(localized: "Packed") : String(localized: "Not packed"))
        .accessibilityHint(isChecked ? String(localized: "Double tap to mark as not packed.") : String(localized: "Double tap to mark as packed."))
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }
}
