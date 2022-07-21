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
    private let player: SimpleSoundPlayer.Type
    private var isNewConversation:Bool = false;

    private var sendingMessages: Set<MessageToSend> = []
    private var askEmailTimer: Timer?

    private(set) var page = Page(size: 50)

    init(viewModel: ChatViewModel, config: Configeration, client: ChatClient, conversationID: ConversationID, player: SimpleSoundPlayer.Type = AudioToolboxSoundPlayer.self, isNewConversation:Bool) {
        self.viewModel = viewModel
        self.client = client
        self.config = config
        self.conversationID = conversationID
        self.player = player
        self.isNewConversation = isNewConversation;

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
                self.client.readConversation(ID: self.conversationID, completion: nil)
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
        
        if isNewConversation{
            client.createContact(with: email.rawValue, in: nil) { _ in }
        }else{
            client.createContact(with: email.rawValue, in: conversationID) { _ in }
        }
        
    }

    func sendContact(_ name: String, _ email: EmailAddress, asMessage: Bool = true) {
        if asMessage {
            sendMessage(with: email.rawValue)
        }
        
        if isNewConversation{
            client.createContact(with: email.rawValue, in: nil) { _ in
                let contactData = CreateContact(email: email.rawValue, name: name)
                self.client.contactTrack(with: contactData) { _ in }
            }
        }else{
            client.createContact(with: email.rawValue, in: conversationID) { _ in
                let contactData = CreateContact(email: email.rawValue, name: name)
                self.client.contactTrack(with: contactData) { _ in }
            }
        }
        
    }

    func getTranscript(completion: @escaping ((URL?) -> Void)) {
        client.downloadTranscript(of: conversationID) { result in
            switch result {
            case .success(let transcript):
                if let urlToSave = try? FileManager.default.getURLInCachesDirectory(for: self.conversationID + ".txt") {
                    try? transcript.write(to: urlToSave, atomically: true, encoding: .utf8)
                    completion(urlToSave)
                } else {
                    completion(nil)
                }
            case .failure:
                completion(nil)
            }
        }
    }

    func sendRating(_ rating: Int) {
        client.updateRating(of: conversationID, to: rating) { result in
            switch result {
            case .success:
                self.viewModel?.updateRating(to: rating)
                self.updateMesages(for: .newMessage)
            case .failure:
                break
            }
        }
    }

    func sendRemark(_ remark: String) {
        client.updateRemark(of: conversationID, to: remark) { result in
            switch result {
            case .success:
                self.viewModel?.updateRemark(to: remark)
                self.updateMesages(for: .newMessage)
            case .failure:
                break
            }
        }
    }

    func visitorIsTyping() {
        let name = config.contact?.name ?? config.pseudoName ?? ""
        client.sendTyping(to: conversationID, as: name)
    }
}

extension ChatController {

    private func updateMesages(for event: ChatViewModel.MessageUpdateEvent) {
        let messages = client.messages[conversationID] ?? []

        let sendingMessageIDs = sendingMessages.map { $0.id }
        let commonIDs = messages.filter { sendingMessageIDs.contains($0.id)}.map { $0.id }

        sendingMessages = sendingMessages.filter({ !commonIDs.contains($0.id) })

        viewModel?.update(messages, sendingMessages: sendingMessages, for: event)
    }

    private func prepareClient() {
        client.clearMessages()

        client.register(observer: self, for: [.messageReceived, .typing, .onlineUsers, .offlineUsers, .conversationUpdated], of: conversationID) { event in
            switch event {
            case .messageReceived(_, let messages):
                guard let messages = messages, !messages.isEmpty else { return }

                if let last = messages.last, !self.sendingMessages.contains(where: { $0.id == last.id }) {
                    self.playReceivedSound()
                }

                self.updateMesages(for: .newMessage)
                self.client.readConversation(ID: self.conversationID, completion: nil)
            case .typing(_, let userID):
                guard let userID = userID else { return }
                guard let user = self.config.users?.first(where: { $0.id == userID }) else { return }

                let userViewModel = CirculerUserProfileViewModel(user: user)

                runOnMain {
                    self.viewModel?.typing?(userViewModel)
                }
            case .onlineUsers(let ids):
                ids.forEach { self.config.updateStatus(of: $0.description, to: .available) }
                self.viewModel?.updateTopBar()
            case .offlineUsers(let ids):
                ids.forEach { self.config.updateStatus(of: $0.description, to: .away) }
                self.viewModel?.updateTopBar()
            case .conversationUpdated:
                guard let conversation = self.client.conversations.first(where: { $0.id == self.conversationID }) else { return }
                self.viewModel?.update(conversation)
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
                self.playSendSound()
            case .failure:
                message.status = .fail
                self.playFailSound()
            }

            self.viewModel?.updateUserReadStatus(to: false)
            self.sendingMessages.update(with: message)
            self.updateMesages(for: .sending)
        }
    }

    private func sendBot(_ message: MessageToSend) {
        var message = message

        client.send(message: message, to: conversationID) { result in
            switch result {
            case .success:
                message.status = .sent
            case .failure:
                message.status = .fail
            }
        }
    }

    private func startAskEmailTimesIfRequire() {
        func askEmail() {
            var blockToSendStr = "Hi there! Currently our team is away, but we’ll be available in a moment. In the meantime, please give us a way to reach you."
            if let teamAvailability = config.teamNextAvailableTime {
                if !teamAvailability.isPastTime,  let teamAvailabilityText = teamAvailability.fromNow {
                    blockToSendStr = "Hi there! Currently our team is away, but we’ll be \(teamAvailabilityText.lowercased()). In the meantime, please give us a way to reach you."
                }
            }
            let message1 = MessageToSend(type: .comment,
                                         contents: [BlockToSend(text: blockToSendStr)],
                                         conversationName: config.pseudoName ?? "",
                                         isBot: true)

            let message2 = MessageToSend(type: .emailAsked,
                                         contents: [],
                                         conversationName: config.pseudoName ?? "",
                                         isBot: true)

            sendBot(message1)
            sendBot(message2)
        }

        guard config.askEmail == .never else { return }
        guard config.contact?.email == nil else { return }
        guard askEmailTimer == nil else { return }

        let messages = client.messages[conversationID] ?? []
        let hasNoReply = messages.allSatisfy({ $0.userID == nil })
        let haventAsked = messages.allSatisfy({ $0.type != .emailAsked })

        guard hasNoReply, haventAsked else { return }

        DispatchQueue.main.async {
            self.askEmailTimer = Timer.scheduledTimer(withTimeInterval: 60 * 2, repeats: false, block: { timer in
                askEmail()
                timer.invalidate()
            })
        }
    }
}

extension ChatController {

    private func playSendSound() {
        player.play(sound: .sent)
    }

    private func playReceivedSound() {
        player.play(sound: .reacived)
    }

    private func playFailSound() {
        player.play(sound: .fail)
    }
}
