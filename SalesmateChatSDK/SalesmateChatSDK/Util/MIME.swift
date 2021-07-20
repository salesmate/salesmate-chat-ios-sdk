//
//  MIME.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 09/04/21.
//

import Foundation
import MobileCoreServices

class MIMEType {
    static let unknown = "application/octet-stream"

    static func mime(for fileExtension: String) -> String {
        guard let extUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil) else {
            return MIMEType.unknown
        }

        guard let mimeUTI = UTTypeCopyPreferredTagWithClass(extUTI.takeUnretainedValue(), kUTTagClassMIMEType) else {
            return MIMEType.unknown
        }

        return String(mimeUTI.takeUnretainedValue())
    }

    static func fileExtension(for mime: String) -> String? {
        guard let mimeUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mime as CFString, nil) else {
            return nil
        }

        guard let extUTI = UTTypeCopyPreferredTagWithClass(mimeUTI.takeRetainedValue(), kUTTagClassFilenameExtension) else {
            return nil
        }

        return String(extUTI.takeUnretainedValue())
    }

    private static func utTypeConformsTo(tagClass: CFString, identifier: String, conformTagClass: CFString) -> Bool {
        guard let uti = UTTypeCreatePreferredIdentifierForTag(tagClass, identifier as CFString, nil) else {
            return false
        }
        return UTTypeConformsTo(uti.takeUnretainedValue(), conformTagClass)
    }

    static func isImage(fileExtension: String) -> Bool {
        return utTypeConformsTo(tagClass: kUTTagClassFilenameExtension, identifier: fileExtension, conformTagClass: kUTTypeImage)
    }

    static func isImage(mime: String) -> Bool {
        return utTypeConformsTo(tagClass: kUTTagClassMIMEType, identifier: mime, conformTagClass: kUTTypeImage)
    }

    static func isAudio(fileExtension: String) -> Bool {
        return utTypeConformsTo(tagClass: kUTTagClassFilenameExtension, identifier: fileExtension, conformTagClass: kUTTypeAudio)
    }

    static func isAudio(mime: String) -> Bool {
        return utTypeConformsTo(tagClass: kUTTagClassMIMEType, identifier: mime, conformTagClass: kUTTypeAudio)
    }

    static func isMPEG4Video(fileExtension: String) -> Bool {
        return utTypeConformsTo(tagClass: kUTTagClassFilenameExtension, identifier: fileExtension, conformTagClass: kUTTypeMPEG4)
    }

    static func isMPEG4Video(mime: String) -> Bool {
        return utTypeConformsTo(tagClass: kUTTagClassMIMEType, identifier: mime, conformTagClass: kUTTypeMPEG4)
    }
}
