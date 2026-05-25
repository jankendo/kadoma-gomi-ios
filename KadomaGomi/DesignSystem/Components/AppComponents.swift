import SwiftUI

struct AppScreen<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                content
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColor.background)
    }
}

struct AppSectionHeader: View {
    let title: String
    let subtitle: String?
    let systemImage: String?

    init(_ title: String, subtitle: String? = nil, systemImage: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(AppColor.appTint)
                    .frame(width: 24, height: 24)
            }
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppColor.text)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColor.secondaryText)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

struct AppBadge: View {
    let text: String
    let color: Color
    let systemImage: String?

    init(_ text: String, color: Color = AppColor.appTint, systemImage: String? = nil) {
        self.text = text
        self.color = color
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .font(AppTypography.badge)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 5)
        .background(color.opacity(0.15), in: Capsule())
        .foregroundStyle(color)
        .accessibilityLabel(text)
    }
}

struct WasteSymbol: View {
    let category: WasteCategory?
    let size: CGFloat

    var body: some View {
        Image(systemName: category?.symbolName ?? "trash.fill")
            .font(.system(size: size * 0.42, weight: .semibold))
            .frame(width: size, height: size)
            .background(AppColor.category(category).opacity(0.16), in: RoundedRectangle(cornerRadius: min(AppRadius.md, size / 4), style: .continuous))
            .foregroundStyle(AppColor.category(category))
            .accessibilityHidden(true)
    }
}

struct AppStateView: View {
    enum Kind {
        case empty
        case error
        case loading
        case success

        var color: Color {
            switch self {
            case .empty:
                return AppColor.secondaryText
            case .error:
                return AppColor.error
            case .loading:
                return AppColor.appTint
            case .success:
                return AppColor.success
            }
        }

        var icon: String {
            switch self {
            case .empty:
                return AppIcon.empty
            case .error:
                return AppIcon.error
            case .loading:
                return AppIcon.update
            case .success:
                return AppIcon.success
            }
        }
    }

    let kind: Kind
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(kind: Kind, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.kind = kind
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                if kind == .loading {
                    ProgressView()
                        .tint(kind.color)
                        .frame(width: 34, height: 34)
                } else {
                    Image(systemName: kind.icon)
                        .font(.title3.weight(.semibold))
                        .frame(width: 34, height: 34)
                        .background(kind.color.opacity(0.14), in: Circle())
                        .foregroundStyle(kind.color)
                }
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppTypography.cardTitle)
                    Text(message)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColor.secondaryText)
                }
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .minimumTapTarget()
            }
        }
        .appCard()
        .accessibilityElement(children: .combine)
    }
}

struct CollectionEventCard: View {
    let title: String
    let date: Date
    let events: [CollectionEvent]
    let categoryProvider: (String) -> WasteCategory?
    let prominence: Prominence

    enum Prominence {
        case primary
        case secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(prominence == .primary ? .title2.weight(.bold) : AppTypography.cardTitle)
                    Text(KadomaDateFormatter.displayDay.string(from: date))
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColor.secondaryText)
                }
                Spacer()
                AppBadge("朝9時まで", color: AppColor.warning, systemImage: AppIcon.time)
            }

            if events.isEmpty {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AppColor.success)
                    Text("出すごみはありません")
                        .font(prominence == .primary ? .title3.weight(.bold) : AppTypography.cardTitle)
                        .foregroundStyle(AppColor.secondaryText)
                }
                .padding(.vertical, AppSpacing.sm)
            } else {
                VStack(spacing: AppSpacing.md) {
                    ForEach(events) { event in
                        CollectionEventRow(event: event, category: categoryProvider(event.categoryId), showsDate: false)
                    }
                }
            }
        }
        .appCard()
        .accessibilityElement(children: .combine)
        .accessibilityHint(events.isEmpty ? "この日はごみ出し予定がありません。" : "ごみ種別と出し方の注意を確認できます。")
    }
}

struct CollectionEventRow: View {
    let event: CollectionEvent
    let category: WasteCategory?
    let showsDate: Bool

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            WasteSymbol(category: category, size: 44)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                    Text(category?.name ?? event.categoryId)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColor.text)
                    if event.requiresReservation {
                        AppBadge("要予約", color: AppColor.warning, systemImage: AppIcon.warning)
                    }
                }
                if showsDate {
                    Text(KadomaDateFormatter.displayDay.string(from: event.date))
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.secondaryText)
                }
                Text(event.note ?? category?.disposalRule ?? "朝9時までに出してください。")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .background(AppColor.secondaryBackground, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.14), in: Circle())
                    .foregroundStyle(color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColor.text)
                    Text(subtitle)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.secondaryText)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppColor.tertiaryText)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(AppColor.separator.opacity(0.35), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .minimumTapTarget()
        .accessibilityHint("\(title)へ移動します。")
    }
}

struct CategoryFilterChip: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.badge)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(isSelected ? color : AppColor.cardBackground, in: Capsule())
                .foregroundStyle(isSelected ? .white : color)
                .overlay(Capsule().stroke(color.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .minimumTapTarget()
        .accessibilityValue(isSelected ? "選択中" : "未選択")
    }
}
