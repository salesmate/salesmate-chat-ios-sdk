//
//  UIKitExtensions.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 28/07/21.
//

import UIKit

extension UIColor {

    convenience init?(hex: String) {
        let red, green, blue: CGFloat
        var hex = hex.trim()

        if hex.hasPrefix("#") {
            hex.removeFirst()
        }

        let start = hex.startIndex
        let hexColor = String(hex[start...])

        guard hexColor.count == 6 else { return nil }

        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt32 = 0

        guard scanner.scanHexInt32(&hexNumber) else { return nil }

        red = CGFloat((hexNumber & 0xff0000) >> 16) / 255
        green = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
        blue = CGFloat(hexNumber & 0x0000ff) / 255

        self.init(red: red, green: green, blue: blue, alpha: 1)
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
        let u = notification.userInfo!

        animationCurve = UIView.AnimationCurve(rawValue: u[UIWindow.keyboardAnimationCurveUserInfoKey] as! Int)!
        animationDuration = u[UIWindow.keyboardAnimationDurationUserInfoKey] as! Double
        isLocal = u[UIWindow.keyboardIsLocalUserInfoKey] as! Bool
        frameBegin = u[UIWindow.keyboardFrameBeginUserInfoKey] as! CGRect
        frameEnd = u[UIWindow.keyboardFrameEndUserInfoKey] as! CGRect
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
