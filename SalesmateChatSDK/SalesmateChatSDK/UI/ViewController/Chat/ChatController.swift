//
//  ChatController.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 13/08/21.
//

import Foundation

class ChatController {

    private weak var viewModel: ChatViewModel?

    private let config: Configeration
    private let client: ChatClient
    private let conversationID: ConversationID
    private var sendingMessages: Set<MessageToSend> = []
    private var askEmailTimer: Timer?

    private(set) var page = Page(size: 50)

    init(viewModel: ChatViewModel, config: Configeration, client: ChatClient, conversationID: ConversationID) {
        self.viewModel = viewModel
        self.client = client
        self.config = config
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
        client.getMessages(of: conversationID, at: page) { result in
            switch result {
            case .success:
                self.updateMesages(for: .pageLoading)
                self.page.next()
            case .failure:
                break
            }
        }
    }

    func sendMessage(with text: String) {
        let message = MessageToSend(type: .comment,
                                    contents: [BlockToSend(text: text)],
                                    conversationName: config.pseudoName ?? "")

        sendingMessages.update(with: message)

        updateMesages(for: .sending)

        send(message)
    }

    func sendMessage(with file: FileToUpload) {
        let message = MessageToSend(type: .comment,
                                    contents: [],
                                    conversationName: config.pseudoName ?? "",
                                    file: file)

        sendingMessages.update(with: message)

        updateMesages(for: .sending)

        uploadFile(for: message)
    }

    func retryMessage(of viewModel: SendingMessageViewModel) {
        guard var message = sendingMessages.first(where: { $0.id == viewModel.id }) else { return }

        message.status = .sending

        sendingMessages.update(with: message)

        updateMesages(for: .sending)

        if message.fileToUpload == nil {
            send(message)
        } else {
            uploadFile(for: message)
        }
    }

    func send(_ email: EmailAddress, asMessage: Bool = true) {
        if asMessage {
            sendMessage(with: email.rawValue)
        }

        client.createContact(with: email.rawValue, in: conversationID) { _ in }
    }
}

extension ChatController {

    private func updateMesages(for event: ChatViewModel.MessageUpdateEvent) {
        let messages = client.messages[conversationID] ?? []
        viewModel?.update(messages, sendingMessages: sendingMessages, for: event)
    }

    private func prepareClient() {
        client.clearMessages()

        client.register(observer: self, for: [.messageReceived], of: conversationID) { event in
            switch event {
            case .messageReceived(_, let messages):
                guard let messages = messages, !messages.isEmpty else { return }
                self.updateMesages(for: .newMessage)
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
                message.fileToUpload = nil
                message.uploadedFile = uploadedFile
                message.contents.append(BlockToSend(from: uploadedFile))

                self.sendingMessages.update(with: message)
                self.send(message)
            case .failure:
                message.status = .fail

                self.sendingMessages.update(with: message)
                self.updateMesages(for: .sending)
            }
        } progress: { progress in
            print("File Upload Progress: \(progress)")
        }
    }

    private func send(_ message: MessageToSend) {
        var message = message

        client.send(message: message, to: conversationID) { result in
            switch result {
            case .success:
                message.status = .sent
                self.startAskEmailTimesIfRequire()
            case .failure:
                message.status = .fail
            }

            self.sendingMessages.update(with: message)
            self.updateMesages(for: .sending)
        }
    }

    private func startAskEmailTimesIfRequire() {
        func askEmail() {
            let message1 = MessageToSend(type: .comment,
                                         contents: [BlockToSend(text: "Give the team a way to reach you:")],
                                         conversationName: config.pseudoName ?? "",
                                         isBot: true)

            let message2 = MessageToSend(type: .emailAsked,
                                         contents: [],
                                         conversationName: config.pseudoName ?? "",
                                         isBot: true)

            send(message1)
            send(message2)
        }

        guard config.askEmail == .never else { return }
        guard config.contact?.email == nil else { return }
        guard askEmailTimer == nil else { return }

        let messages = client.messages[conversationID] ?? []
        let hasNoReply = messages.allSatisfy({ $0.userID == nil })
        let haventAsked = messages.allSatisfy({ $0.type != .emailAsked })

        guard hasNoReply, haventAsked else { return }

        DispatchQueue.main.async {
            self.askEmailTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { timer in
                askEmail()
                timer.invalidate()
            })
        }
    }
}
