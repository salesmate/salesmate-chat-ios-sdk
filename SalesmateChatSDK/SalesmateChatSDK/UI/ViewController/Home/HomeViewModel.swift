//
//  HomeViewModel.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 28/07/21.
//

import Foundation

protocol HomeViewModelType {
    var backgroundColorCode: String { get }
    var actionColorCode: String { get }
    
    var headerLogoURL: URL? { get }
    var backgroundPatternURL: URL? { get }

    var greeting: String { get }
    var teamIntro: String { get }
    
    var newVisitorViewModel: NewVisitorViewModelType { get }
}

class HomeViewModel: HomeViewModelType {
    
    // MARK: - Private Properties
    private let config: Configeration
    private let client: ChatClient

    // MARK: - Properties
    var backgroundColorCode: String = ""
    var actionColorCode: String = ""
    
    var headerLogoURL: URL? = nil
    var backgroundPatternURL: URL? = nil

    var greeting: String = ""
    var teamIntro: String = ""

    var newVisitorViewModel: NewVisitorViewModelType {
        NewVisitorViewModel(config: config)
    }
    
    // MARK: - Init
    init(config: Configeration, client: ChatClient) {
        self.config = config
        self.client = client
        
        prepareTopViewProperties()
    }
    
    // MARK: - Setup
    private func prepareTopViewProperties() {
        guard let look = config.look else { return }
        
        backgroundColorCode = look.backgroundColor
        actionColorCode = look.actionColor
        
        headerLogoURL = URL(string: look.logourl)
        backgroundPatternURL = patternURL(for: look.messengerBackground)
        
        guard let welcome = config.welcome else { return }
        
        greeting = welcome.greetingMessage
        teamIntro = welcome.teamIntro
    }
    
    private func patternURL(for name: String) -> URL? {
        let fileName = name.replacingOccurrences(of: "pattern", with: "pt")
        
        return URL(string: "https://\(config.identity.tenantID)/assets/images/pattern/\(fileName).png")
    }
}
