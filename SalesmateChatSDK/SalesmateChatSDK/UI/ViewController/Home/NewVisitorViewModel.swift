//
//  NewVisitorViewModel.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 28/07/21.
//

import Foundation

protocol NewVisitorViewModelType {
    var responseTime: String { get }
    var showPowerBy: Bool { get }
    var buttonColorCode: String { get }
}

class NewVisitorViewModel: NewVisitorViewModelType {

    // MARK: - Private Properties
    private let config: Configeration

    var responseTime: String = ""
    var showPowerBy: Bool = false
    var buttonColorCode: String = ""
    
    // MARK: - Init
    init(config: Configeration) {
        self.config = config
        
        prepareProperties()
    }
    
    private func prepareProperties() {
        guard let availability = config.availability else { return }
        guard let look = config.look else { return }
        
        responseTime = "The team typically replies \(availability.replyTime)"
        showPowerBy = look.showPoweredBy
        buttonColorCode = look.actionColor
    }
}
