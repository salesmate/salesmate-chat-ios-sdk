//
//  File.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 23/03/21.
//

import Foundation

struct FileToUpload {
    
    let id: UUID = UUID()
    let fileName: String
    let fileData: Data
    let mimeType: String
    
    init(fileName: String, fileData: Data, mimeType: String) {
        self.fileName = fileName
        self.fileData = fileData
        self.mimeType = mimeType
    }
        
    init?(url: URL) {
        let fileName = url.lastPathComponent
        
        guard let fileData = try? Data(contentsOf: url) else { return nil }
        
        let mimeType = MIMEType.mime(for: url.pathExtension)
        
        self.fileName = fileName
        self.fileData = fileData
        self.mimeType = mimeType
    }
}

extension FileToUpload: Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct UploadedFile: Codable {
   
    enum CodingKeys: String, CodingKey {
        case path = "path"
        case name = "fileName"
        case mimeType = "contentType"
        case location = "url"
        case thumbnailPath = "thumbnailPath"
        case thumbnailUrl = "thumbnailUrl"
        case fileId = "file_id"
    }
    
    let path: String
    let name: String
    let mimeType: String
    let location: String
    let thumbnailPath: String?
    let thumbnailUrl: String?
    let fileId: String?
    var refID: UUID?
}

struct File: Codable {
    
    enum CodingKeys: String, CodingKey {
        case name
        case location = "url"
        case mimeType = "content_type"
    }
    
    let name: String?
    let location: String?
    let mimeType: String?
    
    var locationURL: URL? { URL(string: location ?? "") }
}

struct FileToSend: Codable {
    
    enum CodingKeys: String, CodingKey {
        case name
        case gcpName = "gcp_file_name"
        case mimeType = "content_type"
        case thumbnail = "thumbnail"
        case gcpThumbnailName = "gcp_thumbnail_file_name"
        case fileId = "file_id"
    }
    
    let name: String
    let gcpName: String
    let mimeType: String
    let thumbnail: String?
    let gcpThumbnailName: String?
    let fileId:String?
    
    // For internal use only
    private(set) var location: String?

    
    init(from file: UploadedFile) {
        self.name = file.name
        self.gcpName = file.path
        self.mimeType = file.mimeType
        self.thumbnail = file.thumbnailUrl
        self.gcpThumbnailName = file.thumbnailPath
        self.fileId = file.fileId
        
        self.location = file.location
    }
}
