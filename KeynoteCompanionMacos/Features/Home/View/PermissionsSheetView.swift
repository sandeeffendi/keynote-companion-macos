//
//  PermissionsSheetView.swift
//  KeynoteCompanionMacos
//
//  First-run Permissions modal. Mirrors the Settings layout but presents as a sheet:
//  a single "Allow" requests all three accesses, each row exposes an info popover, and
//  the sheet auto-dismisses once every access is granted.
//

import SwiftUI

struct PermissionsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PermissionsSheetViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            GlassEffectContainer(spacing: 0) {
                VStack(spacing: 0) {
                    ForEach(viewModel.rows) { row in
                        PermissionSheetRow(
                            row: row,
                            showsSeparator: row.id != viewModel.rows.last?.id
                        )
                    }
                }
            }
            .padding(.top, AppSpacing.lg)

            Spacer(minLength: 0)

            footer
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.xl)
        .padding(.bottom, AppSpacing.xl)
        .frame(width: Metrics.width, height: Metrics.height)
        .onChange(of: viewModel.allGranted) { _, granted in
            if granted { dismiss() }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSApplication.didBecomeActiveNotification
            )
        ) { _ in
            viewModel.refresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Permissions")
                .font(AppFont.settingHead)
                .foregroundStyle(AppColor.textPrimary)

            Text("Allow the access below to start practicing your public speaking.")
                .font(AppFont.statusSubtitle)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var footer: some View {
        HStack(spacing: AppSpacing.md) {
            Spacer(minLength: 0)

            Button("Cancel") { dismiss() }
                .buttonStyle(.glass)
                .controlSize(.large)

            Button(action: viewModel.requestAll) {
                Text("Allow")
                    .frame(minWidth: Metrics.allowButtonMinWidth)
            }
            .buttonStyle(.glassProminent)
            .tint(AppColor.controlAccent)
            .controlSize(.large)
            .disabled(viewModel.isRequesting)
        }
    }

    private enum Metrics {
        static let width: CGFloat = 560
        static let height: CGFloat = 420
        static let allowButtonMinWidth: CGFloat = 44
    }
}

private struct PermissionSheetRow: View {
    let row: PermissionsSheetViewModel.Row
    let showsSeparator: Bool

    @State private var isShowingInfo = false

    var body: some View {
        rowContent
            .overlay(alignment: .bottom) {
                if showsSeparator {
                    Rectangle()
                        .fill(AppColor.separator)
                        .frame(height: 1)
                        .padding(.leading, Metrics.separatorLeadingPadding)
                }
            }
    }

    private var rowContent: some View {
        HStack(spacing: AppSpacing.lg) {
            Image(systemName: row.icon)
                .font(AppFont.sizeIcon)
                .foregroundStyle(AppColor.iconPrimary)
                .frame(width: Metrics.iconWidth)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(row.title)
                    .font(AppFont.settingTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)

                Text(row.subtitle)
                    .font(AppFont.settingDescription)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: AppSpacing.sm)

            infoButton

            statusLabel
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(height: Metrics.rowHeight)
        .contentShape(Rectangle())
    }

    private var infoButton: some View {
        Button {
            isShowingInfo = true
        } label: {
            Image(systemName: AppIcon.permissionInfo)
                .font(AppFont.settingTitle)
                .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("About \(row.title)")
        .popover(isPresented: $isShowingInfo, arrowEdge: .bottom) {
            Text(row.info)
                .font(AppFont.settingDescription)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(AppSpacing.lg)
                .frame(width: Metrics.popoverWidth)
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        Text(row.status == .authorized ? "Allowed" : "Disallowed")
            .font(AppFont.button)
            .foregroundStyle(
                row.status == .authorized
                    ? AppColor.permissionGranted : AppColor.textTertiary
            )
            .frame(width: Metrics.statusWidth, alignment: .trailing)
            .accessibilityLabel(
                row.status == .authorized
                    ? "\(row.title) allowed" : "\(row.title) not allowed"
            )
    }

    private enum Metrics {
        static let rowHeight: CGFloat = 72
        static let iconWidth: CGFloat = 36
        static let separatorLeadingPadding: CGFloat = 68
        static let popoverWidth: CGFloat = 260
        static let statusWidth: CGFloat = 78
    }
}

#if DEBUG
#Preview {
    PermissionsSheetView()
}
#endif
