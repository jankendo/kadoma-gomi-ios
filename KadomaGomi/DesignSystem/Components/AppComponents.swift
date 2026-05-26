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
        .background(AppColor.background.ignoresSafeArea())
        .scrollContentBackground(.hidden)
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
        .padding(.vertical, 6)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous).stroke(color.opacity(0.18), lineWidth: 1))
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
            .background(AppColor.categoryBackground(category), in: Circle())
            .overlay(
                Circle()
                    .stroke(AppColor.category(category).opacity(0.22), lineWidth: 1)
            )
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

        var actionColor: Color {
            switch self {
            case .empty, .loading:
                return AppColor.appTint
            case .error:
                return AppColor.error
            case .success:
                return AppColor.success
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
                        .frame(width: 40, height: 40)
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
                Button(action: action) {
                    Label(actionTitle, systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
                }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(kind.actionColor)
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
                        .font(prominence == .primary ? AppTypography.heroTitle : AppTypography.cardTitle)
                    Text(KadomaDateFormatter.displayDay.string(from: date))
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColor.secondaryText)
                }
                Spacer()
                AppBadge("朝9時まで", color: AppColor.warning, systemImage: AppIcon.time)
            }

            if events.isEmpty {
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2.weight(.semibold))
                        .frame(width: prominence == .primary ? 56 : 44, height: prominence == .primary ? 56 : 44)
                        .background(AppColor.softMint, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                        .foregroundStyle(AppColor.success)
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("出すごみはありません")
                            .font(prominence == .primary ? .title3.weight(.bold) : AppTypography.cardTitle)
                            .foregroundStyle(AppColor.text)
                        Text("今日はゆっくり確認だけで大丈夫です。")
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColor.secondaryText)
                    }
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
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(AppColor.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .stroke(prominence == .primary ? AppColor.appTint.opacity(0.32) : AppColor.separator, lineWidth: prominence == .primary ? 1.2 : 0.8)
        )
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
        .background(AppColor.categoryBackground(category), in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(AppColor.category(category).opacity(0.18), lineWidth: 1)
        )
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
                    .frame(width: 42, height: 42)
                    .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
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
            .background(AppColor.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(color.opacity(0.22), lineWidth: 1)
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
                .background(isSelected ? color : color.opacity(0.11), in: Capsule())
                .foregroundStyle(isSelected ? .white : color)
                .overlay(Capsule().stroke(color.opacity(0.45), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .minimumTapTarget()
        .accessibilityValue(isSelected ? "選択中" : "未選択")
    }
}
