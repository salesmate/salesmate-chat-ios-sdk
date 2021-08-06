//
//  UIKitExtensions.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 28/07/21.
//

import UIKit

extension UIColor {

    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt32 = 0

        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt32(&rgb) else { return nil }

        if length == 6 {
            red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            blue = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 8 {
            red = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            green = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            blue = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            alpha = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    var isDark: Bool {
        var red, green, blue, alpha: CGFloat
        (red, green, blue, alpha) = (0, 0, 0, 0)
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let lum = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        return lum < 0.50
    }
}

extension UIImageView {

    // load image async from internet
    func setImage(from link: URL) {
        // Request
        let request = URLRequest(url: link)

        // Session
        let session = URLSession.shared

        // Data task
        let datatask = session.dataTask(with: request) { (data, _, error) -> Void in
            guard let data = data, error == nil else { return }
            guard let image = UIImage(data: data) else { return }

            OperationQueue.main.addOperation { self.image = image }
        }

        datatask.resume()
    }
}

extension Bundle {
    static var salesmate: Bundle { Bundle(for: SalesmateChat.self) }
}

extension UIImage {

    convenience init?(_ name: String) {
        self.init(named: name, in: .salesmate, compatibleWith: nil)
    }

    static var startNewChat: UIImage { UIImage("ic-start-new-chat")! }
    static var attachment: UIImage { UIImage("ic-attachment")! }
}

extension UIViewController {

    func add(child: UIViewController, in container: UIView? = nil) {
        guard let containerView = container ?? view else { return }

        addChild(child)
        child.view.frame = containerView.bounds
        containerView.addSubview(child.view)

        child.didMove(toParent: self)
    }
}

extension UIView {

    func addAndFill(in parentView: UIView, with insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false

        parentView.addSubview(self)

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -insets.right),
            topAnchor.constraint(equalTo: parentView.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -insets.bottom)
        ])
    }
}

extension UIColor {

    var foregroundColor: UIColor {
        isDark ? Self.lightForegroundColor : Self.darkForegroundColor
    }

    var secondaryForegroundColor: UIColor {
        isDark ? Self.secondaryLightForegroundColor : Self.secondaryDarkForegroundColor
    }

    static var darkForegroundColor: UIColor { .black }
    static var secondaryDarkForegroundColor: UIColor { UIColor(hex: "47484A") ?? .black }

    static var lightForegroundColor: UIColor { .white }
    static var secondaryLightForegroundColor: UIColor { UIColor(hex: "DEEBFF") ?? .white }
}

struct KeyboardInfo {
    var animationCurve: UIView.AnimationCurve
    var animationDuration: Double
    var isLocal: Bool
    var frameBegin: CGRect
    var frameEnd: CGRect
}

extension KeyboardInfo {

    init?(_ notification: Notification) {
        guard notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification else { return nil }
        let userInfo = notification.userInfo!

        animationCurve = UIView.AnimationCurve(rawValue: userInfo[UIWindow.keyboardAnimationCurveUserInfoKey] as! Int)!
        animationDuration = userInfo[UIWindow.keyboardAnimationDurationUserInfoKey] as! Double
        isLocal = userInfo[UIWindow.keyboardIsLocalUserInfoKey] as! Bool
        frameBegin = userInfo[UIWindow.keyboardFrameBeginUserInfoKey] as! CGRect
        frameEnd = userInfo[UIWindow.keyboardFrameEndUserInfoKey] as! CGRect
    }

    var animationCurveOption: UIView.AnimationOptions {
        switch animationCurve {
        case .easeIn:
            return .curveEaseIn
        case .easeOut:
            return .curveEaseOut
        case .easeInOut:
            return .curveEaseInOut
        case .linear:
            return .curveLinear
        @unknown default:
            return .curveLinear
        }
    }
}
