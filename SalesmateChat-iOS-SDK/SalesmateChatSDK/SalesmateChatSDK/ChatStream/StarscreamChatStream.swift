//
//  ChatClientWebScket.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 23/03/21.
//

import Network
@_implementationOnly import Starscream
@_implementationOnly import SwiftyJSON

class StarscreamChatStream {

    enum ConnectionStatus {
        case notConnected
        case connecting
        case authenticating
        case connected

        var isNotConnected: Bool { self == .notConnected }
        var isConnecting: Bool { self == .connecting }
        var isAuthenticating: Bool { self == .authenticating }
        var isConnected: Bool { self == .connected }
    }

    private let config: Configeration
    private var socket: WebSocket?
    private var status: ConnectionStatus = .notConnected
    private let relay: ChatEventRelay = ChatEventRelay()
    private let internetMonitor = NWPathMonitor()
    private let payloads: ChatStreamPayloadMaker

    private var onConnect: ((Result<Void, ChatError>) -> Void)?

    init(for config: Configeration) {
        self.config = config
        self.payloads = PayloadMaker(config: config)
    }

    private func connect() {
        guard status.isNotConnected else { return }

        var builder = URLComponents()

        builder.scheme = "wss"
        builder.host = config.identity.tenantID
        builder.path = "/socketcluster/"

        guard let url = builder.url else { return }

        socket = WebSocket(request: URLRequest(url: url))

        socket?.respondToPingWithPong = true
        socket?.delegate = self

        status = .connecting

        socket?.connect()

        run(afterDelay: 3) {
            self.connect()
        }
    }
}

extension StarscreamChatStream: ChatStream {

    var isReady: Bool { status.isConnected }

    func register(observer: AnyObject, for events: [ChatEventToObserve], of conversation: ConversationID?, onEvent: @escaping (ChatEvent) -> Void) {
        let observation = ChatEventRelay.Observation(observer: observer,
                                                     events: events,
                                                     conversation: conversation,
                                                     onEvent: onEvent)
        relay.add(observation: observation)
    }

    func connect(completion: @escaping (Result<Void, ChatError>) -> Void) {
        switch status {
        case .notConnected:
            onConnect = completion
            connect()
        case .connecting:
            onConnect = completion
        case .authenticating:
            onConnect = completion
            handshake()
        case .connected:
            completion(.success(()))
        }
    }

    func sendTyping(for conversation: String, and uniqueID: String) {
        typing(conversation: conversation, uniqueID: uniqueID)
    }
}

extension StarscreamChatStream: WebSocketDelegate {

    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected:
            print("websocket is connected")
            authenticate()
        case .disconnected(let reason, let code):
            status = .notConnected
            print("websocket is disconnected: \(reason) with code: \(code)")
            connect()
        case .text(let string):
            handleReceivedText(string)
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            status = .notConnected
            print("websocket is cancelled")
        case .error(let error):
            status = .notConnected
            print("websocket error: \(error.debugDescription)")
            connect()
        }
    }
}

extension StarscreamChatStream {

    private func monitorInternet() {
        internetMonitor.pathUpdateHandler = { path in
            print((path.status == .satisfied) ? "Internet Connected" : "Internet Disconnected")

            guard path.status == .satisfied else { return }
            guard self.status.isNotConnected else { return }

            self.connect()
        }

        let queue = DispatchQueue(label: "InternetMonitor")
        internetMonitor.start(queue: queue)
    }
}

// handle text (JSON) message.
extension StarscreamChatStream {

    private func handleReceivedText(_ text: String) {
        guard !text.isEmpty else {
            // Send back empty string to keep connection alive.
            socket?.write(string: "")
            return
        }

        print("Received text: \(text)")

        let json = JSON(parseJSON: text)

        let isAuthenticatedPath: [JSONSubscriptType] = [Payload.Keys.data, Payload.Keys.isAuthenticated]

        if let isAuthenticated = json[isAuthenticatedPath].bool, isAuthenticated {
            status = .connected

            onConnect?(.success(()))
            onConnect = nil

            subscribe()
            monitorInternet()
        } else if json[Payload.Keys.event].exists() {
            let payload = Payload(from: json)
            guard let event = PayloadHandler.handle(payload) else { return }
            relay(event)
        }
    }
}

// Send Events
extension StarscreamChatStream {

    private func authenticate() {
        guard status.isConnecting else { return }

        status = .authenticating

        handshake()
    }

    private func handshake() {
        guard status.isAuthenticating else { return }
        guard let text = payloads.handshakeObject()?.utf8 else { return }

        socket?.write(string: text)

        run(afterDelay: 2) {
            self.handshake()
        }
    }

    private func subscribe() {
        guard let dataObjects = payloads.subscribeObjects() else { return }
        dataObjects.forEach { socket?.write(string: $0.utf8 ?? "") }
    }

    private func typing(conversation: String, uniqueID: String) {
        guard let text = payloads.typingObject(for: conversation, and: uniqueID)?.utf8 else { return }

        socket?.write(string: text)
    }
}
