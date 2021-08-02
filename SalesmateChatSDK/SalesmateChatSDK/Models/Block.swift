//
//  Content.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 23/03/21.
//

import Foundation

enum BlockType: String, Codable {
    case text
    case image
    case html
    case file
    case orderedList
    case unorderedList
}

struct BlockToSend: Codable {

    let type: BlockType
    let text: String?
    let attachment: FileToSend?

    init(text: String) {
        self.type = .text
        self.text = text
        self.attachment = nil
    }

    init(from file: UploadedFile) {
        self.type = file.mimeType.contains("image") ? .image : .file
        self.text = nil
        self.attachment = FileToSend(from: file)
    }

    init(html text: String) {
        self.type = .html
        self.text = text
        self.attachment = nil
    }
}

struct Block: Codable {

    let id: String
    let blockType: BlockType
    let isDraft: Bool
    let orderedNo: IntegerID
    let text: String?
    let file: File?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case blockType = "block_type"
        case isDraft = "is_draft"
        case orderedNo = "ordered_no"
        case text = "text"
        case file = "fileAttachmentData"
    }
}
