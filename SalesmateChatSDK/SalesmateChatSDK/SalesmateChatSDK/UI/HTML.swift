//
//  HTML.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 04/08/21.
//

import Foundation
import UIKit

typealias HTML = String

extension HTML {

    // MARK: - Static
    private static var approxMaxWidth: Float {
        let screenWidth = UIScreen.main.bounds.width
        let widthA = Float(screenWidth - 114)
        let widthB = Float(screenWidth * 0.80 - 30)

        return Swift.min(widthA, widthB)
    }

    // MARK: - Instance
    private var parser: HTMLParser.Type { FoundationHTMLParser.self }

    private func insertPhoneLinks() -> String {
        let text = NSMutableString(string: self)

        let phonePattern = #"""
            \b\+?\d{1,4}?[-.\s]?\(?\d{1,3}?\)?[-.\s]?\d{1,4}[-.\s]?\d{1,4}[-.\s]?\d{1,9}\b
        """#

        guard let phoneRegEx = try? NSRegularExpression(pattern: phonePattern, options: []) else { return self }

        phoneRegEx.replaceMatches(in: text,
                                  options: [],
                                  range: NSRange(location: 0, length: text.length),
                                  withTemplate: "<a href=tel:$0>$0</a>")

        return String(text)
    }

    func preProcessedHTML() -> HTML {
        let HTMLWithPhone = self.insertPhoneLinks()

        let processedHTML = """
            <html>
            <head>
            <style>
            body {
                font-size: 15;
                font-family:'-apple-system';
                font-weight: normal;
            }
            img {
                width: \(Self.approxMaxWidth) !important;
                height: auto !important;
            }
            </style>
            </head>
            <body>
            \(HTMLWithPhone)
            </body>
            </html>
            """
        return processedHTML
    }

    var attributedString: NSAttributedString? {
        parser.attributedString(from: self)
    }
}

private protocol HTMLParser {
    static func attributedString(from html: HTML) -> NSAttributedString?
}

private struct FoundationHTMLParser: HTMLParser {

    static func attributedString(from html: HTML) -> NSAttributedString? {
        let preProcessedHTML = html.preProcessedHTML()

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] =
            [.documentType: NSAttributedString.DocumentType.html,
             .characterEncoding: String.Encoding.utf8.rawValue]

        guard let textData = preProcessedHTML.data(using: .utf8) else { return nil }
        guard let attributedText = try? NSAttributedString(data: textData,
                                                           options: options,
                                                           documentAttributes: nil) else { return nil }

        return attributedText
    }
}
