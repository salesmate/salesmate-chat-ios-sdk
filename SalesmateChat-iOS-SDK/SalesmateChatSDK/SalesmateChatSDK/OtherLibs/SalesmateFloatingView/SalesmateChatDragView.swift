//
//  SalesmateChatDragView.swift
//  SalesmateChatSDK
//
//  Created by Vishal Nandoriya on 07/07/22.
//

import UIKit

public enum DragDirection: Int{
    case any = 0
    case horizontal
    case vertical
}

let kScreenH = UIScreen.main.bounds.height
let kScreenW = UIScreen.main.bounds.width
let isIphoneX: Bool = kScreenH >= 812.0 ? true: false
let kStatusBarH: CGFloat = isIphoneX == true ? 44 : 20
let kSafeBottomH: CGFloat = isIphoneX == true ? 34 : 0
let kNavBarH: CGFloat = isIphoneX ? 88 : 64

class SalesmateChatDragView: UIView {
    
    public var dragEnable: Bool = true
    public var freeRect: CGRect = CGRect.zero
    public var dragDirection: DragDirection = DragDirection.any
    
    @IBOutlet weak var messageMainStackView: UIStackView!
    @IBOutlet weak var messageOneMoreView: UIView!
    @IBOutlet weak var messageView1: UIView!
    @IBOutlet weak var messageView2: UIView!
    @IBOutlet weak var messageView3: UIView!
    @IBOutlet weak var messageTextLabel: UILabel!
    @IBOutlet weak var senderTextLabel: UILabel!
    @IBOutlet weak var messageImageView: UIImageView!
    
    public var messageCount: Int = 1
    
    public var isKeepBounds: Bool = false
    
    public var forbidenOutFree: Bool = false
    
    public var hasNavagation: Bool = false
        
    public var forbidenEnterStatusBar: Bool = true
    
    public var fatherIsController: Bool = true
    
    //    @objc lazy var contentViewForDrag: UIView = {
    //        let contentV = UIView.init()
    //        contentV.clipsToBounds = true
    //        contentV.backgroundColor = .red
    //        self.addSubview(contentV)
    //        return contentV
    //    }()
    
    public var clickDragViewBlock: ((SalesmateChatDragView) -> ())?
    public var beginDragBlock: ((SalesmateChatDragView) -> ())?
    public var duringDragBlock: ((SalesmateChatDragView) -> ())?
    public var endDragBlock: ((SalesmateChatDragView) -> ())?
    
    
    private var leftMove: String = "leftMove"
    private var rightMove: String = "rightMove"
    
    private var animationTime: TimeInterval = 0.5
    private var startPoint: CGPoint = CGPoint.zero
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    private var endaAimationTime: TimeInterval = 0.2
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let superview = self.superview {
            freeRect = CGRect(x: 0, y: kScreenH - superview.bounds.size.height - 34 , width: kScreenW, height: superview.bounds.size.height)
        }
    }
    
    func setup() {
        
        if let superview = self.superview {
            freeRect = CGRect.init(origin: CGPoint.zero, size: superview.bounds.size)
        }
        self.clipsToBounds = true
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(clickDragView))
        self.addGestureRecognizer(singleTap)
        self.frame = CGRect(x: -kScreenW, y: kScreenH - self.bounds.size.height - 34 , width: kScreenW, height: self.bounds.size.height)
        panGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(dragAction(pan:)))
        
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        self.addGestureRecognizer(panGestureRecognizer)
    }
    
    func showFloatview() {
        var currentWindow: UIWindow? = UIApplication.shared.keyWindow
        currentWindow = currentWindow ?? UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        currentWindow = currentWindow ?? UIApplication.shared.windows.first
        if currentWindow?.subviews.first != self {
            currentWindow?.addSubview(self)
            self.alpha = 0.0
            UIView.animate(withDuration: 1, animations: {
                self.alpha = 1.0
                let moveRight = CGAffineTransform(translationX: +(self.frame.width), y: 0.0)
                currentWindow?.subviews.last!.transform = moveRight
            })
        }
    }
    
    func removeFloatview() {
        messageCount = 1
        self.removeFromSuperview()
    }
    
    
    func updateMessageUI(withMessageText: String, withSenderText: String) {
        self.applyShadowWithView(view: self.messageView3)
        self.applyShadowWithView(view: self.messageView2)
        self.applyShadowWithView(view: self.messageView1)
        
        switch messageCount {
        case 1:
            self.messageView1.isHidden = false
            self.messageView2.isHidden = true
            self.messageView3.isHidden = true
            self.messageOneMoreView.isHidden = true
        case 2:
            self.messageView1.isHidden = false
            self.messageView2.isHidden = false
            self.messageView3.isHidden = true
            self.messageOneMoreView.isHidden = true
        case 3:
            self.messageView1.isHidden = false
            self.messageView2.isHidden = false
            self.messageView3.isHidden = false
            self.messageOneMoreView.isHidden = true
        case 4:
            self.messageView1.isHidden = false
            self.messageView2.isHidden = false
            self.messageView3.isHidden = false
            self.messageOneMoreView.isHidden = false
        default:
            break
        }

        self.messageTextLabel.text = withMessageText
        self.senderTextLabel.text = withSenderText
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    func applyShadowWithView(view: UIView) {
        view.layer.cornerRadius = 10
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.4
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 5
    }
        
    @objc func clickDragView() {
        clickDragViewBlock?(self)
    }
    
    @objc func dragAction(pan: UIPanGestureRecognizer){
        if dragEnable == false {
            return
        }
        
        switch pan.state {
        case .began:
            
            beginDragBlock?(self)
            
            pan.setTranslation(CGPoint.zero, in: self)
            startPoint = pan.translation(in: self)
        case .changed:
            
            duringDragBlock?(self)
            
            if forbidenOutFree == true && (frame.origin.x < 0 || frame.origin.x > freeRect.size.width - frame.size.width || frame.origin.y < 0 || frame.origin.y > freeRect.size.height - frame.size.height){
                var newframe: CGRect = self.frame
                if frame.origin.x < 0 {
                    newframe.origin.x = 0
                }else if frame.origin.x > freeRect.size.width - frame.size.width {
                    newframe.origin.x = freeRect.size.width - frame.size.width
                }
                if frame.origin.y < 0 {
                    newframe.origin.y = 0
                }else if frame.origin.y > freeRect.size.height - frame.size.height{
                    newframe.origin.y = freeRect.size.height - frame.size.height
                }
                
                UIView.animate(withDuration: endaAimationTime) {
                    self.frame = newframe
                }
                return
            }
            
            if fatherIsController && forbidenEnterStatusBar && frame.origin.y < kStatusBarH {
                var newframe: CGRect = self.frame
                newframe.origin.y = kStatusBarH
                UIView.animate(withDuration: endaAimationTime) {
                    self.frame = newframe
                }
                return
            }
            if fatherIsController && frame.origin.y > freeRect.size.height - frame.size.height - kSafeBottomH {
                var newframe: CGRect = self.frame
                newframe.origin.y = freeRect.size.height - frame.size.height - kSafeBottomH
                UIView.animate(withDuration: endaAimationTime) {
                    self.frame = newframe
                }
            }
            
            if fatherIsController && hasNavagation && frame.origin.y < kNavBarH{
                var newframe: CGRect = self.frame
                newframe.origin.y = kNavBarH
                UIView.animate(withDuration: endaAimationTime) {
                    self.frame = newframe
                }
                return
            }
            
            
            let point: CGPoint = pan.translation(in: self)
            var dx: CGFloat = 0.0
            var dy: CGFloat = 0.0
            switch dragDirection {
            case .any:
                dx = point.x - startPoint.x
                dy = point.y - startPoint.y
            case .horizontal:
                dx = point.x - startPoint.x
                dy = 0
            case .vertical:
                dx = 0
                dy = point.y - startPoint.y
            }
            
            let newCenter: CGPoint = CGPoint.init(x: center.x + dx, y: center.y + dy)
            center = newCenter
            pan.setTranslation(CGPoint.zero, in: self)
            
        case .ended:
            keepBounds()
            endDragBlock?(self)
        default:
            break
        }
        
    }
    
    private func keepBounds() {
        let centerX: CGFloat = freeRect.origin.x + (freeRect.size.width - frame.size.width)*0.5
        var rect: CGRect = self.frame
        if isKeepBounds == false {
            if frame.origin.x < freeRect.origin.x {
                
                UIView.beginAnimations(leftMove, context: nil)
                UIView.setAnimationCurve(.easeInOut)
                UIView.setAnimationDuration(animationTime)
                rect.origin.x = freeRect.origin.x
                self.frame = rect
                UIView.commitAnimations()
            }else if freeRect.origin.x + freeRect.size.width < frame.origin.x + frame.size.width{
                
                UIView.beginAnimations(rightMove, context: nil)
                UIView.setAnimationCurve(.easeInOut)
                UIView.setAnimationDuration(animationTime)
                rect.origin.x = freeRect.origin.x + freeRect.size.width - frame.size.width
                self.frame = rect
                UIView.commitAnimations()
            }
            
        } else if isKeepBounds == true{
            if frame.origin.x < centerX {
                
                UIView.beginAnimations(leftMove, context: nil)
                UIView.setAnimationCurve(.easeInOut)
                UIView.setAnimationDuration(animationTime)
                rect.origin.x = freeRect.origin.x
                self.frame = rect
                UIView.commitAnimations()
            }else{
                
                UIView.beginAnimations(rightMove, context: nil)
                UIView.setAnimationCurve(.easeInOut)
                UIView.setAnimationDuration(animationTime)
                rect.origin.x = freeRect.origin.x + freeRect.size.width - frame.size.width
                self.frame = rect
                UIView.commitAnimations()
            }
        }
        
        if frame.origin.y < freeRect.origin.y {
            UIView.beginAnimations("topMove", context: nil)
            UIView.setAnimationCurve(.easeInOut)
            UIView.setAnimationDuration(animationTime)
            rect.origin.y = freeRect.origin.y
            self.frame = rect
            UIView.commitAnimations()
        }else if freeRect.origin.y + freeRect.size.height <  frame.origin.y + frame.size.height {
            UIView.beginAnimations("bottomMove", context: nil)
            UIView.setAnimationCurve(.easeInOut)
            UIView.setAnimationDuration(animationTime)
            rect.origin.y = freeRect.origin.y + freeRect.size.height - frame.size.height
            self.frame = rect
            UIView.commitAnimations()
        }
    }
}

