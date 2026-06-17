//
//  RetryRowView.swift
//  KeynoteCompanionMacos
//
//  Created by Rahmadina on 15/06/26.
//

import SwiftUI

struct AttemptRowView: View {
    struct Attempt: Identifiable {
        let name: String
        let id = UUID()
    }
    
    private var attempts = [
        Attempt(name: "Attempt 1"),
        Attempt(name: "Attempt 2"),
        Attempt(name: "Attempt 3")
    ]
    var body: some View {
        ForEach(attempts){
            attempt in
            HStack {
                    Text(attempt.name).font(.body)
                    Spacer()
                    Text("170 WPM").font(.body)
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AttemptRowView()
}
