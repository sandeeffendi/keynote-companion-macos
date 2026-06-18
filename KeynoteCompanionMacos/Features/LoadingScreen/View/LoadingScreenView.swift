//
//  LoadingScreenView.swift
//  KeynoteCompanionMacos
//
//  Created by Fajar Ahmad Kurniazi on 07/06/26.
//

import Network
import SwiftUI

struct LoadingScreenView: View {

    let onFinished: @MainActor () -> Void

    @State private var isWaitingForInternet = false
    @State private var retryToken = UUID()

    var body: some View {
        ZStack {
            Text("TIEMPO.")
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(AppColor.textPrimary)
                .tracking(6)
                .accessibilityLabel("Tiempo")

            ProgressView()
                .controlSize(.small)
                .scaleEffect(1.5)
                .offset(y: AppSize.splashWindowHeight * 0.25)
                .accessibilityLabel("Loading Tiempo")

            if isWaitingForInternet {
                VStack(spacing: 16) {
                    Text("Waiting for internet connection…")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        retryToken = UUID()
                    }
                    .buttonStyle(.glassProminent)
                    .tint(AppColor.controlAccent)
                }
                .offset(y: AppSize.splashWindowHeight * 0.35)
                .transition(.opacity)
            }
        }
        .frame(
            width: AppSize.splashWindowWidth,
            height: AppSize.splashWindowHeight
        )
        .animation(.easeInOut(duration: 0.3), value: isWaitingForInternet)
        .task(id: retryToken) {
            await run()
        }
    }

    @MainActor
    private func run() async {
        isWaitingForInternet = false

        // Brief initial delay so the splash renders before any connectivity check
        do { try await Task.sleep(for: .seconds(2)) } catch { return }
        guard !Task.isCancelled else { return }

        let connected = await checkConnectivity()
        guard !Task.isCancelled else { return }

        if connected {
            do { try await Task.sleep(for: .seconds(1)) } catch { return }
            guard !Task.isCancelled else { return }
            onFinished()
        } else {
            isWaitingForInternet = true
            await waitForConnectivity()
            guard !Task.isCancelled else { return }
            onFinished()
        }
    }

    /// Checks the current path status. NWPathMonitor fires its handler immediately
    /// on start with the current path, so this resolves on the next runloop tick.
    private func checkConnectivity() async -> Bool {
        await withCheckedContinuation { continuation in
            var done = false
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "com.kumpeni.Tiempo.check", qos: .utility)
            monitor.pathUpdateHandler = { path in
                guard !done else { return }
                done = true
                monitor.cancel()
                continuation.resume(returning: path.status == .satisfied)
            }
            monitor.start(queue: queue)
        }
    }

    /// Suspends until the network path becomes satisfied.
    private func waitForConnectivity() async {
        await withCheckedContinuation { continuation in
            var done = false
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "com.kumpeni.Tiempo.wait", qos: .utility)
            monitor.pathUpdateHandler = { path in
                guard !done, path.status == .satisfied else { return }
                done = true
                monitor.cancel()
                continuation.resume()
            }
            monitor.start(queue: queue)
        }
    }
}

struct LoadingScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingScreenView(onFinished: {})
    }
}
