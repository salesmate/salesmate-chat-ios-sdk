//
//  UIKitExtensions.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 28/07/21.
//

import UIKit
@_implementationOnly import Nuke

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

    func loadImage(from source: ImageSource, completion: (() -> Void)? = nil) {
        switch source {
        case .url(let link):
            self.loadImage(with: link, completion: completion)
        case .local(let name):
            if let image = UIImage(name) {
                self.image = image
            }
            completion?()
        }
    }

    func loadImage(with link: URL, completion: (() -> Void)? = nil) {
        Nuke.loadImage(with: link, into: self) { _ in completion?() }
    }
}

extension Bundle {
    static var salesmate: Bundle { Bundle(for: SalesmateChat.self) }
}

extension UIImage {

    convenience init?(_ name: String) {
        self.init(named: name, in: .salesmate, compatibleWith: nil)
    }

    static var startNewChat = UIImage("ic-start-new-chat")!
    static var attachment = UIImage("ic-attachment")!
    static var smallAttachment = UIImage("ic-attachment-small")!
    static var typingDot = UIImage("typing-animation-dot")!
}

extension UIViewController {

    func add(child: UIViewController, in container: UIView? = nil) {
        guard let containerView = container ?? view else { return }

        addChild(child)
        child.view.frame = containerView.bounds
        containerView.addSubview(child.view)

        child.didMove(toParent: self)
    }

    func showHUD() {
        runOnMain {
            guard let hud = HUDVC.shared else { return }

            hud.modalPresentationStyle = .overFullScreen

            self.present(hud, animated: false, completion: nil)
        }
    }

    func hideHUD() {
        runOnMain {
            if self.presentedViewController is HUDVC {
                self.dismiss(animated: false, completion: nil)
            }
        }
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

    static func loadFromNib() -> Self {
        let named = String(describing: Self.self)
        guard let view = UINib(nibName: named, bundle: .salesmate).instantiate(withOwner: nil, options: nil)[0] as? Self else {
            fatalError("First element in xib file \(named) is not of type \(named)")
        }
        return view
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

public extension UITableView {

    /// Index path of last row in tableView.
    var indexPathForLastRow: IndexPath? {
        guard let lastSection = lastSection else { return nil }
        return indexPathForLastRow(inSection: lastSection)
    }

    /// Index of last section in tableView.
    var lastSection: Int? {
        return numberOfSections > 0 ? numberOfSections - 1 : nil
    }

    /// Number of all rows in all sections of tableView.
    ///
    /// - Returns: The count of all rows in the tableView.
    func numberOfRows() -> Int {
        var section = 0
        var rowCount = 0
        while section < numberOfSections {
            rowCount += numberOfRows(inSection: section)
            section += 1
        }
        return rowCount
    }

    /// IndexPath for last row in section.
    ///
    /// - Parameter section: section to get last row in.
    /// - Returns: optional last indexPath for last row in section (if applicable).
    func indexPathForLastRow(inSection section: Int) -> IndexPath? {
        guard numberOfSections > 0, section >= 0 else { return nil }
        guard numberOfRows(inSection: section) > 0 else {
            return IndexPath(row: 0, section: section)
        }
        return IndexPath(row: numberOfRows(inSection: section) - 1, section: section)
    }

    /// Reload data with a completion handler.
    ///
    /// - Parameter completion: completion handler to run after reloadData finishes.
    func reloadData(_ completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0, animations: {
            self.reloadData()
        }, completion: { _ in
            completion()
        })
    }

    /// Remove TableFooterView.
    func removeTableFooterView() {
        tableFooterView = nil
    }

    /// Remove TableHeaderView.
    func removeTableHeaderView() {
        tableHeaderView = nil
    }

    /// Dequeue reusable UITableViewCell using class name for indexPath.
    ///
    /// - Parameters:
    ///   - name: UITableViewCell type.
    ///   - indexPath: location of cell in tableView.
    /// - Returns: UITableViewCell object with associated class name.
    func dequeueReusableCell<T: UITableViewCell>(withClass name: T.Type, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: String(describing: name), for: indexPath) as? T else {
            fatalError(
                "Couldn't find UITableViewCell for \(String(describing: name)), make sure the cell is registered with table view")
        }
        return cell
    }

    /// Register UITableViewCell using class name.
    ///
    /// - Parameter name: UITableViewCell type.
    func register<T: UITableViewCell>(cellWithClass name: T.Type) {
        register(T.self, forCellReuseIdentifier: String(describing: name))
    }

    /// Register UITableViewCell with .xib file using only its corresponding class.
    ///               Assumes that the .xib filename and cell class has the same name.
    ///
    /// - Parameters:
    ///   - name: UITableViewCell type.
    ///   - bundleClass: Class in which the Bundle instance will be based on.
    func register<T: UITableViewCell>(nibWithCellClass name: T.Type) {
        let identifier = String(describing: name)

        register(UINib(nibName: identifier, bundle: .salesmate), forCellReuseIdentifier: identifier)
    }

    /// Check whether IndexPath is valid within the tableView.
    ///
    /// - Parameter indexPath: An IndexPath to check.
    /// - Returns: Boolean value for valid or invalid IndexPath.
    func isValidIndexPath(_ indexPath: IndexPath) -> Bool {
        return indexPath.section >= 0 &&
            indexPath.row >= 0 &&
            indexPath.section < numberOfSections &&
            indexPath.row < numberOfRows(inSection: indexPath.section)
    }

    /// Safely scroll to possibly invalid IndexPath.
    ///
    /// - Parameters:
    ///   - indexPath: Target IndexPath to scroll to.
    ///   - scrollPosition: Scroll position.
    ///   - animated: Whether to animate or not.
    func safeScrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        guard indexPath.section < numberOfSections else { return }
        guard indexPath.row < numberOfRows(inSection: indexPath.section) else { return }
        scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
    }
}

extension UIDevice {
    var isIPhone: Bool { userInterfaceIdiom == .phone }
    var isIPad: Bool { userInterfaceIdiom == .pad }
}

extension UIViewController {

    @discardableResult
    func showAlert(title: String?, message: String?, buttonTitles: [String]? = nil, highlightedButtonIndex: Int? = nil, completion: ((Int) -> Void)? = nil) -> UIAlertController {

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        var allButtons = buttonTitles ?? [String]()

        if allButtons.count == 0 { allButtons.append("OK") }

        for index in 0..<allButtons.count {
            let buttonTitle = allButtons[index]
            let action = UIAlertAction(title: buttonTitle, style: .default, handler: { _ in
                completion?(index)
            })

            alertController.addAction(action)

            if let highlightedButtonIndex = highlightedButtonIndex, index == highlightedButtonIndex {
                alertController.preferredAction = action
            }
        }

        if #available(iOS 13.0, *) {
            alertController.overrideUserInterfaceStyle = .light
        }

        present(alertController, animated: true, completion: nil)

        return alertController
    }
}

extension UITextField {
    var isEmpty: Bool { text?.isEmpty ?? false }
}
