//
//  SimpleSound.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 15/09/21.
//

import Foundation
import AudioToolbox

enum Sound {
    case sent
    case reacived
    case fail
}

protocol SimpleSoundPlayer {
    static func play(sound: Sound)
}

class AudioToolboxSoundPlayer: SimpleSoundPlayer {

    static func play(sound: Sound) {
        switch sound {
        case .sent: AudioServicesPlayAlertSoundWithCompletion(1104, nil)
        case .reacived: AudioServicesPlayAlertSoundWithCompletion(1105, nil)
        case .fail: AudioServicesPlayAlertSoundWithCompletion(1073, nil)
        }
    }
}
