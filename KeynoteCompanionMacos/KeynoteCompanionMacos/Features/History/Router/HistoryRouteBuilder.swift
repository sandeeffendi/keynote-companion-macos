import SwiftUI

struct HistoryRouteBuilder {
    @ViewBuilder
    static func build (_ route: HistoryRoute) -> some View {
        switch route {
            case .first:
            HistoryView(
                viewModel: HistoryViewModel()
            )
        }
    }
}
