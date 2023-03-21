//
//  PreviousConversationsView.swift
//  SirTalkaLot
//
//  Created by Ben Cady on 3/17/23.
//

import SwiftUI

struct PreviousConversationsView: View {
    @State private var conversationFiles: [URL] = []

    var onConversationSelected: ((String) -> Void)?
    var body: some View {
        List(conversationFiles, id: \.self) { fileURL in
            Button(action: {
                if let onConversationSelected = onConversationSelected {
                    let title = fileURL.deletingPathExtension().lastPathComponent
                    onConversationSelected(title)
                }
            }) {
                Text(fileURL.deletingPathExtension().lastPathComponent)
            }
        }
        .onAppear(perform: loadConversationFiles)
        .navigationBarTitle("Previous Conversations", displayMode: .inline)
    }
    
    func loadConversationFiles() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: [])
            conversationFiles = fileURLs.filter { $0.pathExtension == "txt" }
        } catch {
            print("Error loading conversation files: \(error.localizedDescription)")
        }
    }
}

struct PreviousConversationsView_Previews: PreviewProvider {
    static var previews: some View {
        PreviousConversationsView()
    }
}
