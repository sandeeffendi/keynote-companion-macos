import Foundation
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: HistoryViewModel
    
    init(viewModel: HistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack{
            Text("Ini History")
                .font(.largeTitle)
            
            Button("Go to Settings") {
                router.replace(with: .settings(.account))
            }
        }
    }
}
