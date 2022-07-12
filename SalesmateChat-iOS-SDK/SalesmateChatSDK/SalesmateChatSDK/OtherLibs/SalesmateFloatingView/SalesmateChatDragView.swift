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

public enum BubbleType {
    case rateBubble
    case messageBubble
}
//class GradientView: UIView {
//    override open class var layerClass: AnyClass {
//        return CAGradientLayer.classForCoder()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        let gradientLayer = self.layer as! CAGradientLayer
//        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor, UIColor.clear.cgColor]
//        gradientLayer.locations = [0.0, 0.15, 0.25, 0.75, 0.85, 1.0]
//        backgroundColor = UIColor.clear
//    }
//}

let kScreenH = UIScreen.main.bounds.height
let kScreenW = UIScreen.main.bounds.width
let isIphoneX: Bool = kScreenH >= 812.0 ? true: false
let kStatusBarH: CGFloat = isIphoneX == true ? 44 : 20
let kSafeBottomH: CGFloat = isIphoneX == true ? 34 : 0
let kNavBarH: CGFloat = isIphoneX ? 88 : 64

@IBDesignable
class SalesmateChatDragView: UIView {
    
    public var dragEnable: Bool = true
    public var freeRect: CGRect = CGRect.zero
    public var dragDirection: DragDirection = DragDirection.any
    public var bubbleType: BubbleType = BubbleType.messageBubble
    @IBOutlet weak var contentViewForDrag: UIView!

    @IBOutlet weak var rateStackView: UIStackView!
    @IBOutlet weak var rateView: UIView!
    @IBOutlet weak var rateImageView: UIImageView!
    @IBOutlet weak var rateTextLabel: UILabel!


    @IBOutlet weak var messageMainStackView: UIStackView!
    @IBOutlet weak var messageOneMoreView: UIView!
    @IBOutlet weak var messageView1: UIView!
    @IBOutlet weak var messageView2: UIView!
    @IBOutlet weak var messageView3: UIView!
    @IBOutlet weak var messageTextLabel: UILabel!
    @IBOutlet weak var messageImageView: UIImageView!
    
    public var messageCount: Int = 1

    @IBInspectable
    public var isKeepBounds: Bool = false
    
    @IBInspectable
    public var forbidenOutFree: Bool = true
    
    @IBInspectable
    public var hasNavagation: Bool = true
    
    @IBInspectable
    public var forbidenEnterStatusBar: Bool = false
    
    @IBInspectable
    public var fatherIsController: Bool = false
        
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
        setupUI()
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
        contentViewForDrag.frame = CGRect.init(origin: CGPoint.zero, size: self.bounds.size)
    }
    
    func setup() {
        if let superview = self.superview {
            freeRect = CGRect.init(origin: CGPoint.zero, size: superview.bounds.size)
        }
        self.clipsToBounds = true
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(clickDragView))
        self.addGestureRecognizer(singleTap)
        self.frame = CGRect(x: 0, y: kScreenH - self.bounds.size.height - 34 , width: kScreenW, height: self.bounds.size.height)
        panGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(dragAction(pan:)))
                
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        self.addGestureRecognizer(panGestureRecognizer)
        
        setupBubbleUI()
    }
    
    func setupBubbleUI() {
        if self.bubbleType == .rateBubble {
            self.rateStackView.isHidden = false
            self.messageMainStackView.isHidden = true
            self.applyShadowWithView(view: self.rateView)
        } else if self.bubbleType == .messageBubble{
            self.rateStackView.isHidden = true
            self.messageMainStackView.isHidden = false
            self.applyShadowWithView(view: self.messageView3)
            self.applyShadowWithView(view: self.messageView2)
            self.applyShadowWithView(view: self.messageView1)
            updateMessageUI()
        }
    }
    func updateMessageUI() {
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
    }
    
    func applyShadowWithView(view: UIView) {
        view.layer.cornerRadius = 10
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.4
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 5
    }
    
    func setupUI() {
        let metalView = UIView(frame: contentViewForDrag.bounds)
//        metalView.backgroundColor = .white
//        metalView.alpha = 0.9
//        let layer0 = CAGradientLayer()
//        layer0.colors = [
//          UIColor(red: 0.98, green: 0.984, blue: 0.988, alpha: 1).cgColor,
//          UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor,
//          UIColor(red: 1, green: 1, blue: 1, alpha: 0).cgColor
//        ]
//        layer0.locations = [0, 0.54, 1]
//        layer0.startPoint = CGPoint(x: 0.25, y: 0.5)
//        layer0.endPoint = CGPoint(x: 0.75, y: 0.5)
//        layer0.transform = CATransform3DMakeAffineTransform(CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0.48, ty: 1))
//        layer0.bounds = metalView.bounds.insetBy(dx: -0.5*metalView.bounds.size.width, dy: -0.5*metalView.bounds.size.height)
//        layer0.position = metalView.center
//        metalView.layer.addSublayer(layer0)
//
//
//        self.insertSubview(metalView, at: 0)
//        metalView.translatesAutoresizingMaskIntoConstraints = false
        
//        let gradientLayer = CAGradientLayer()
//        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.white.cgColor]
//        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
//        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
//        gradientLayer.locations = [0, 1]
//        gradientLayer.frame = bounds
//
//        se.layer.mask = gradientLayer

//        let transparent = UIColor(white: 0, alpha: 0).cgColor
//        let opaque = UIColor(white: 1, alpha: 1).cgColor
//        
//        let maskLayer = CALayer()
//        maskLayer.frame = self.bounds
//
//        let gradientLayer = CAGradientLayer()
//        gradientLayer.frame = CGRect(x:self.bounds.origin.x, y:0, width:self.bounds.size.width, height:self.bounds.size.height)
//        gradientLayer.colors = [transparent, opaque, opaque, transparent]
//        gradientLayer.locations = [0.0, 0.3, 0.5, 1.0]
//        //metalView.layer.addSublayer(gradientLayer)
////        self.layer.insertSublayer(gradientLayer, at: 0)
//        maskLayer.addSublayer(gradientLayer)
//        self.layer.insertSublayer(maskLayer, at: 0)
//        contentViewForDrag.layer.insertSublayer(maskLayer, at: 0)
//        metalView.translatesAutoresizingMaskIntoConstraints = false
        
        
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

