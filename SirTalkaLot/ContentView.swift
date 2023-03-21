//
//  ContentView.swift
//  SirTalkaLot
//  bc
//  Created by Ben Cady on 3/17/23.
//

import SwiftUI

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var conversation: [String] = []
    @State private var conversationTitle: String = ""
    @State private var isRecording: Bool = false
    @State private var showingPreviousConversations = false
    private let whisperASR = WhisperASR()
    private let textToSpeech = TextToSpeech()
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(conversation.indices, id: \.self) { index in
                            MessageBubble(isUser: index % 2 == 0, text: conversation[index])
                        }
                    }
                }
                .padding()
                .navigationBarTitle("GPT Chat")
                .navigationBarItems(leading: Button(action: {
                    showingPreviousConversations = true
                }) {
                    Text("Previous Conversations")
                }, trailing: HStack {
                    // ... (the rest of your trailing items)
                    TextField("Title...", text: $conversationTitle)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Button(action: {
                        saveConversation(title: conversationTitle)
                    }) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 30))
                    }
                    
                    Button(action: {
                        loadConversation(title: conversationTitle)
                    }) {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.system(size: 30))
                    }
                })
                
                HStack {
                    TextField("Type your message...", text: $inputText, onCommit: {
                        if !inputText.isEmpty {
                            sendTypedMessage()
                        }
                    })
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    Button(action: {
                        if !inputText.isEmpty {
                            sendTypedMessage()
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 30))
                    }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 30))
                            .padding(.trailing)
                    }
                    
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingPreviousConversations) {
            PreviousConversationsView()
        }
    }
    func loadConversation(title: String) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("\(title).txt")
        
        do {
            let conversationText = try String(contentsOf: fileURL, encoding: .utf8)
            conversation = conversationText.components(separatedBy: "\n")
            print("Conversation loaded successfully.")
        } catch {
            print("Error loading conversation: \(error.localizedDescription)")
        }
    }
    
    func saveConversation(title: String) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("\(title).txt")
        
        let conversationText = conversation.joined(separator: "\n")
        
        do {
            try conversationText.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Conversation saved successfully.")
        } catch {
            print("Error saving conversation: \(error.localizedDescription)")
        }
    }
    
    func sendTypedMessage() {
        let message = inputText
        inputText = ""
        
        OpenAIAPI.sendRequest(prompt: "User: \(message)\nGPT-3, you are an AI language model designed to engage in a friendly and helpful conversation. Your response:", completion: { result in
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.conversation.append(message)
                    self.conversation.append(response)
                    self.textToSpeech.speak(text: response)
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        })
    }
    
    func sendMessage() {
        if !isRecording {
            isRecording = true
            
            whisperASR.startRecording(completion: { result in
                DispatchQueue.main.async {
                    self.isRecording = false
                    
                    switch result {
                    case .success(let message):
                        self.inputText = message
                        self.whisperASR.stopRecording() // Stop recording before sending the message
                        
                        OpenAIAPI.sendRequest(prompt: "User: \(message)\nGPT-3, you are an AI language model designed to engage in a friendly and helpful conversation. Your response:", completion: { result in
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                switch result {
                                case .success(let response):
                                    self.conversation.append(message)
                                    self.conversation.append(response)
                                    self.textToSpeech.speak(text: response)
                                case .failure(let error):
                                    print("Error: \(error.localizedDescription)")
                                }
                            }
                        })
                    case .failure(let error):
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }, recordingStopped: {
                self.isRecording = false
            })
        } else {
            whisperASR.stopRecording()
        }
    }
}

struct MessageBubble: View {
    var isUser: Bool
    var text: String

    var body: some View {
        HStack {
            if isUser {
                Spacer()
            }

            Text(text)
                .padding(10)
                .background(isUser ? Color.blue : Color.gray)
                .foregroundColor(isUser ? .white : .black)
                .cornerRadius(10)

            if !isUser {
                Spacer()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
