//
//  ChatController.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 13/08/21.
//

import Foundation

class ChatController {

    private weak var viewModel: ChatViewModel?

    private let client: ChatClient
    private let conversationID: ConversationID
    private var sendingMessages: Set<MessageToSend> = []

    private(set) var page = Page(size: 50)

    init(viewModel: ChatViewModel, client: ChatClient, conversationID: ConversationID) {
        self.viewModel = viewModel
        self.client = client
        self.conversationID = conversationID

        prepareClient()
    }

    func startLoadingDetails() {
        client.getDetail(of: conversationID) { result in
            switch result {
            case .success(let conversation):
                self.viewModel?.update(conversation)
                self.getMessages()
            case .failure:
                break
            }
        }
    }

    func getMessages() {
        func updateMesages() {
            guard let messages = client.messages[conversationID] else { return }
            viewModel?.update(messages, sendingMessages: sendingMessages, for: .pageLoading)
        }

        client.getMessages(of: conversationID, at: page) { result in
            switch result {
            case .success:
                updateMesages()
                self.page.next()
            case .failure:
                break
            }
        }
    }

    func sendMessage(with text: String) {
        func updateMesages() {
            guard let messages = client.messages[conversationID] else { return }
            viewModel?.update(messages, sendingMessages: sendingMessages, for: .sending)
        }

        let message = MessageToSend(type: .comment, contents: [BlockToSend(text: text)])

        sendingMessages.update(with: message)

        updateMesages()

        send(message)
    }

    func sendMessage(with file: FileToUpload) {
        func updateMesages() {
            guard let messages = client.messages[conversationID] else { return }
            viewModel?.update(messages, sendingMessages: sendingMessages, for: .sending)
        }

        let message = MessageToSend(type: .comment, contents: [], file: file)

        sendingMessages.update(with: message)

        updateMesages()

        uploadFile(for: message)
    }
}

extension ChatController {

    private func prepareClient() {
        func updateNewMesages() {
            guard let messages = client.messages[conversationID] else { return }
            viewModel?.update(messages, sendingMessages: sendingMessages, for: .newMessage)
        }

        client.clearMessages()

        client.register(observer: self, for: [.messageReceived], of: conversationID) { event in
            switch event {
            case .messageReceived(_, let messages):
                guard let messages = messages, !messages.isEmpty else { return }
                updateNewMesages()
            default:
                print("This event(\(event)) is not observed by SalesmateChatClient")
            }
        }
    }

    private func uploadFile(for message: MessageToSend) {
        var message = message

        guard let file = message.fileToUpload else { return }

        client.upload(file: file) { result in
            switch result {
            case .success(let uploadedFile):
                message.uploadedFile = uploadedFile
                message.contents.append(BlockToSend(from: uploadedFile))
                self.sendingMessages.update(with: message)
                self.send(message)
            case .failure:
                message.status = .fail
                self.sendingMessages.update(with: message)
            }
        } progress: { progress in
            print("File Upload Progress: \(progress)")
        }
    }

    private func send(_ message: MessageToSend) {
        func updateMesages() {
            guard let messages = client.messages[conversationID] else { return }
            viewModel?.update(messages, sendingMessages: sendingMessages, for: .sending)
        }

        var message = message

        client.send(message: message, to: conversationID) { result in
            switch result {
            case .success: message.status = .sent
            case .failure: message.status = .fail
            }

            self.sendingMessages.update(with: message)
            updateMesages()
        }
    }
}
