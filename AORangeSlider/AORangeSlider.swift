//
//  AORangeSlider.swift
//  AORangeSlider
//
//  Created by YangWeicheng on 15/05/2017.
//  Copyright © 2017 YWC. All rights reserved.
//

import UIKit

public protocol AORangeSliderDelegate: AnyObject {
    func rangeSliderDidBeginTracking(_ slider: AORangeSlider)
    func rangeSliderWillDrawTrackImage(_ slider: AORangeSlider, drawView: UIView)
}


@IBDesignable
@objc open class AORangeSlider: UIControl {

    /// default 0.0
    @objc @IBInspectable open var minimumValue:Double = 0.0 {
        didSet {
            _lowValue = minimumValue
            setNeedsLayout()
        }
    }
    /// default 1.0
    @objc @IBInspectable open var maximumValue:Double = 1.0 {
        didSet {
            _highValue = maximumValue
            setNeedsLayout()
        }
    }
    
    /// default 0.0, could be negative. The minimum distance between the low value and high value
    @objc @IBInspectable open var minimumDistance:Double = 0.0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// default 0.0
    @objc @IBInspectable open var stepValue:Double = 0.0 {
        didSet {
            setNeedsLayout()
        }
    }

    /// default false. If true, the slider ball will not move until it hit a new step.
    @objc open var stepValueContinuously = false

    /// stepValueInternal = stepValueContinuously ? stepValue : 0.0f;
    private var stepValueInternal = 0.0

    /// default true. If false, it will not trigger valueChanged until the touch ends.
    @objc open var changeValueContinuously = true

    /// default false, if true, it become a single thumb slider
    @objc open var isHighHandleHidden = false {
        didSet {
            setNeedsLayout()
        }
    }

    /// default false, isHighHandleHidden counterpart, should be useless
    @objc open var isLowHandleHidden = false {
        didSet {
            setNeedsLayout()
        }
    }

    /// low center point
    @objc open private(set) var lowCenter: CGPoint = .zero

    /// high center point
    @objc open private(set) var highCenter: CGPoint = .zero

    /// default doing nothing, will call this block when lowCenter and highCenter changed
    @objc open var valuesChangedHandler:() -> Void = {}

    @objc open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "frame" {
            guard let handle = object as? UIImageView else {
                return
            }
            if handle == lowHandle {
                lowCenter = lowHandle.center
                valuesChangedHandler()
            } else if handle == highHandle {
                highCenter = highHandle.center
                valuesChangedHandler()
            }
        }
    }

    deinit {
        lowHandle.removeObserver(self, forKeyPath: "frame")
        highHandle.removeObserver(self, forKeyPath: "frame")
    }

    /// setLowValue would call layoutSubviews, must not call setLowValue in the layoutSubviews
    private var _lowValue = 0.0
    /// default 0.0, set method does not send action
    @objc @IBInspectable open var lowValue: Double {
        set {
            var value = newValue
            if stepValueInternal > 0 {
                value = round(value / stepValueInternal) * stepValueInternal
            }

            value = min(value, maximumValue)
            value = max(value, minimumValue)
            if !lowMaximumValue.isNaN {
                value = min(value, lowMaximumValue)
            }
            value = min(value, highValue - minimumDistance)
            _lowValue = value
            setNeedsLayout()
        }
        get {
            return _lowValue
        }
    }

    /// setHighValue would call layoutSubviews, must not call setHighValue in the layoutSubviews
    private var _highValue = 0.0
    /// default = maximumValue, does not send action
    @objc @IBInspectable open var highValue: Double {
        set {
            var value = newValue
            if stepValueInternal > 0 {
                value = round(value / stepValueInternal) * stepValueInternal
            }
            value = max(value, minimumValue)
            value = min(value, maximumValue)
            if !highMinimumValue.isNaN {
                value = max(value, highMinimumValue)
            }
            value = max(value, lowValue + minimumDistance)
            _highValue = value
            setNeedsLayout()
        }
        get {
            return _highValue
        }
    }

    /// move slider animatedly. does not send action
    @objc open func setValue(low: Double, high: Double, animated: Bool) {
        var duration = 0.0
        if animated {
            duration = 0.25
        }
        UIView.animate(withDuration: duration, delay: 0, options: .beginFromCurrentState, animations: {
            if !low.isNaN {
                self.lowValue = low
            }
            if !high.isNaN {
                self.highValue = high
            }
            self.layoutIfNeeded() // must include this line in the animation block
        }) { _ in
        }
    }

    ///  maximum value for left thumb, default nan
    @objc open var lowMaximumValue = Double.nan

    /// minimum value for right thumb, default nan
    @objc open var highMinimumValue = Double.nan

    /// make left thumb easy to touch. Default UIEdgeInsetsMake(-5, -5, -5, -5)
    @objc open var lowTouchEdgeInsets = UIEdgeInsets(top: -5, left: -5, bottom: -5, right: -5)
    /// make right thumb easy to touch. Default UIEdgeInsetsMake(-5, -5, -5, -5)
    @objc open var highTouchEdgeInsets = UIEdgeInsets(top: -5, left: -5, bottom: -5, right: -5)

    /// the imageView of value bar
    private var trackImageView: UIImageView!

    /// the length of default ball
    private let systemBallLength: CGFloat = 28.0

    /// the color of value bar
    @objc @IBInspectable open var trackColor:UIColor? = #colorLiteral(red: 0, green: 0.4793452024, blue: 0.9990863204, alpha: 1) {
        didSet {
            setNeedsLayout()
        }
    }
    /// the image of value bar
    @objc @IBInspectable open var trackImage:UIImage? {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// the color of value bar when crossed
    @objc @IBInspectable open var trackCrossedColor:UIColor? = .red {
        didSet {
            setNeedsLayout()
        }
    }

    /// the image of value bar when crossed
    @objc @IBInspectable open var trackCrossedImage:UIImage? {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// backgroundImage of the bar, default is a gray 1x2 image
    @objc @IBInspectable open var trackBackgroundColor: UIColor = .gray {
        didSet {
            self.trackBackgroundImage = getImage(color: self.trackBackgroundColor, size: CGSize(width: 1, height: 2))
        }
    }
    
    /// backgroundImage of the bar, default is a gray 1x2 image
    @objc @IBInspectable open var trackBackgroundImage: UIImage! {
        didSet {
            self.trackBackgroundImageView.image = trackBackgroundImage
            
            setNeedsLayout()
        }
    }

    /// Default is nil, and use the shadow ball of system
    @objc @IBInspectable open var lowHandleImageNormal: UIImage? {
        didSet {
            if lowHandleImageNormal == nil {
                becomeSystemBall(ball: lowHandle)
            } else {
                backToImage(ball: lowHandle)
                //Inspectable
                lowHandle.image = lowHandleImageNormal
            }
        }
    }

    /// Default is nil, and use the shadow ball of system
    @objc @IBInspectable open var highHandleImageNormal: UIImage? {
        didSet {
            if highHandleImageNormal == nil {
                becomeSystemBall(ball: highHandle)
            } else {
                backToImage(ball: highHandle)
                //Inspectable
                highHandle.image = highHandleImageNormal
            }
        }
    }

    @objc open var lowHandleImageHighlighted: UIImage?
    @objc open var highHandleImageHighlighted: UIImage?

    private var trackBackgroundImageView: UIImageView!

    /// Keep it private, given that it is useless to change its image directly
    private var lowHandle: UIImageView!
    /// Keep it private, given that it is useless to change its image directly
    private var highHandle: UIImageView!

    private var lowTouchOffset = 0.0
    private var highTouchOffset = 0.0

    @objc public override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    @objc required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }

    func trackImageForCurrentValues() -> UIImage? {
        if lowValue <= highValue {
            if trackImage != nil {
                return trackImage
            }else if(trackColor != nil) {
                return getImage(color: trackColor!, size: CGSize(width: 1, height: 2))
            }else {
                return getImage(color: #colorLiteral(red: 0, green: 0.4793452024, blue: 0.9990863204, alpha: 1), size: CGSize(width: 1, height: 2))
            }
        } else {
            if trackCrossedImage != nil {
                return trackCrossedImage
            }else if(trackCrossedColor != nil) {
                return getImage(color: trackCrossedColor!, size: CGSize(width: 1, height: 2))
            }else {
                return getImage(color: .red, size: CGSize(width: 1, height: 2))
            }
            
        }
    }

    private func configureViews() {

        _lowValue = minimumValue
        _highValue = maximumValue
        lowMaximumValue = Double.nan
        highMinimumValue = Double.nan

        trackBackgroundImageView = UIImageView()
        trackBackgroundImage = getImage(color: #colorLiteral(red: 0.7333333333, green: 0.7333333333, blue: 0.7333333333, alpha: 1), size: CGSize(width: 1, height: 2))
        addSubview(self.trackBackgroundImageView)

        trackImageView = UIImageView()
        addSubview(trackImageView)

        lowHandle = UIImageView()
        addSubview(lowHandle)
        lowHandle.contentMode = .center
        highHandle = UIImageView()
        addSubview(highHandle)
        highHandle.contentMode = .center
        lowHandle.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
        highHandle.addObserver(self, forKeyPath: "frame", options: .new, context: nil)

        becomeSystemBall(ball: lowHandle)
        becomeSystemBall(ball: highHandle)
    }

    func lowValueForCenterX(x: Double) -> Double {
        let padding = Double(lowHandle.frame.size.width / 2.0)
        let valueGap = maximumValue - minimumValue
        let lengthMinusPadding = Double(self.frame.size.width) - padding * 2
        var value: Double = minimumValue + (x - padding) / lengthMinusPadding * valueGap

        // Inhabit setValue programmatically over range
        value = max(value, minimumValue)
        value = min(value, highValue - minimumDistance)

        return value
    }

    func highValueForCenterX(x: Double) -> Double {
        let padding = Double(highHandle.frame.size.width / 2.0)
        let valueGap = maximumValue - minimumValue
        let lengthMinusPadding = Double(self.frame.size.width) - padding * 2
        var value: Double = minimumValue + (x - padding) / lengthMinusPadding * valueGap

        // Inhabit setValue programmatically over range
        value = min(value, maximumValue)
        value = max(value, lowValue + minimumDistance)

        return value
    }

    func trackRect() -> CGRect {
        let lowHandleWidth = lowHandle.image?.size.width ?? systemBallLength
        let highHandleWidth = highHandle.image?.size.width ?? systemBallLength
        let y = trackBackgroundRect().minY
        var x = min(lowHandle.frame.minX, highHandle.frame.minX) + lowHandleWidth / 2
        let h = trackBackgroundRect().height
        var rightX = max(lowHandle.frame.maxX, highHandle.frame.maxX) - highHandleWidth / 2
        var w = rightX - x
        if isLowHandleHidden == true {
            x = 0
            w = rightX
        }
        if isHighHandleHidden == true {
            rightX = max(lowHandle.frame.maxX, highHandle.frame.maxX)
            w = rightX - x
        }
        let rect = CGRect(x: x, y: y, width: w, height: h)
        return rect
    }
    
    public var lowImageHorizontalPadding: CGFloat = 0
    public var highImageHorizontalPadding: CGFloat = 0
    
    override open func layoutSubviews() {
        super.layoutSubviews()

        if isLowHandleHidden {
            _lowValue = minimumValue
        }
        if isHighHandleHidden {
            _highValue = maximumValue
        }

        // lowHandle
        lowHandle.image = lowHandleImageNormal
        lowHandle.highlightedImage = lowHandleImageHighlighted
        lowHandle.isHidden = isLowHandleHidden
        if lowHandle.image == nil {
            lowHandle.frame = handleRectFor(value: lowValue, size: CGSize(width: systemBallLength, height: systemBallLength))
        } else {
            var imageSize = lowHandle.image!.size
            imageSize.width -= 2 * lowImageHorizontalPadding
            lowHandle.frame = handleRectFor(value: lowValue, size: imageSize)
        }

        // highHandle
        highHandle.image = highHandleImageNormal
        highHandle.highlightedImage = highHandleImageHighlighted
        highHandle.isHidden = isHighHandleHidden
        if highHandle.image == nil {
            highHandle.frame = handleRectFor(value: highValue, size: CGSize(width: systemBallLength, height: systemBallLength))
        } else {
            var imageSize = highHandle.image!.size
            imageSize.width -= 2 * highImageHorizontalPadding
            highHandle.frame = handleRectFor(value: highValue, size: imageSize)
        }
        
        trackBackgroundImageView.frame = trackBackgroundRect()

        trackImageView.image = trackImageForCurrentValues()
        trackImageView.frame = trackRect()

    }

    func trackBackgroundRect() -> CGRect {
        let x: Double = 0.0
        let y: Double = Double(self.frame.size.height - trackBackgroundImage.size.height) / 2
        let width: Double = Double(self.frame.size.width)
        let height: Double = Double(trackBackgroundImage.size.height)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    func handleRectFor(value: Double, size: CGSize) -> CGRect {
        var handleRect = CGRect(origin: CGPoint.zero, size: size)

        let xValue = Double(self.bounds.size.width - handleRect.size.width) * (value - minimumValue) / (maximumValue - minimumValue)
        let originY = Double(self.bounds.size.height) / 2.0 - Double(handleRect.size.height) / 2

        let originPoint = CGPoint(x: xValue, y: originY)
        handleRect.origin = originPoint
        return handleRect.integral
    }

    private func becomeSystemBall(ball: UIImageView) {
        ball.layer.cornerRadius = systemBallLength / 2
        ball.layer.shadowOffset = CGSize(width: 0, height: 2)
        ball.layer.shadowOpacity = 0.5
        ball.backgroundColor = .white
        ball.layer.shadowColor = UIColor.black.cgColor
    }

    private func backToImage(ball: UIImageView) {
        ball.layer.cornerRadius = 0
        ball.layer.shadowOffset = CGSize.zero
        ball.layer.shadowOpacity = 0
        ball.backgroundColor = .clear
        ball.layer.shadowColor = UIColor.clear.cgColor
    }
    
    
    public weak var delegate: AORangeSliderDelegate?

    public var islowHandleSelected: Bool {
        lowHandle.isHighlighted
    }

    public var isHighHandleSelected: Bool {
        highHandle.isHighlighted
    }
    
    
    // MARK: - override UIControl method
    
    /// begin track, decide which thumb response to the action
    override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let touchPoint = touch.location(in: self)
        var _lowTouchEdgeInsets = lowTouchEdgeInsets
        _lowTouchEdgeInsets.left -= lowImageHorizontalPadding
        _lowTouchEdgeInsets.right -= lowImageHorizontalPadding
        let lowRect = lowHandle.frame.inset(by: _lowTouchEdgeInsets)
        
        var _highTouchEdgeInsets = highTouchEdgeInsets
        _highTouchEdgeInsets.left -= highImageHorizontalPadding
        _highTouchEdgeInsets.right -= highImageHorizontalPadding
        let highRect = highHandle.frame.inset(by: _highTouchEdgeInsets)

        if lowRect.contains(touchPoint) {
            if !highRect.contains(touchPoint) || (lowHandle === subviews.last) {
                lowHandle.isHighlighted = true
                lowTouchOffset = Double(touchPoint.x - lowHandle.center.x)
                bringSubviewToFront(lowHandle)
            }
        }

        if highRect.contains(touchPoint) {
            if !lowRect.contains(touchPoint) || (highHandle === subviews.last) {
                highHandle.isHighlighted = true
                highTouchOffset = Double(touchPoint.x - highHandle.center.x)
                bringSubviewToFront(highHandle)
            }
        }

        stepValueInternal = stepValueContinuously ? stepValue : 0.0

        delegate?.rangeSliderDidBeginTracking(self)

        if changeValueContinuously {
            sendActions(for: .valueChanged)
        }

        return true
    }

    /// update positions for lower thumb and higher thumb
    override open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if lowHandle.isHighlighted == false && highHandle.isHighlighted == false {
            return true
        }
        let touchPoint = touch.location(in: self)

        if lowHandle.isHighlighted {

            let newValue = lowValueForCenterX(x: Double(touchPoint.x) - lowTouchOffset)

            if newValue < lowValue || !highHandle.isHighlighted {
                highHandle.isHighlighted = false
                bringSubviewToFront(lowHandle)

                let pointX = Double(touchPoint.x)
                let low = lowValueForCenterX(x: pointX)
                setValue(low: low, high: Double.nan, animated: stepValueContinuously)
            } else {
                lowHandle.isHighlighted = false
            }

        }

        if highHandle.isHighlighted {

            let newValue = lowValueForCenterX(x: Double(touchPoint.x))

            if newValue > highValue || !lowHandle.isHighlighted {

                lowHandle.isHighlighted = false
                bringSubviewToFront(highHandle)

                let pointX = Double(touchPoint.x.native)
                let high = highValueForCenterX(x: pointX)
                setValue(low: Double.nan, high: high, animated: stepValueContinuously)

            } else {
                highHandle.isHighlighted = false
            }
        }

        if changeValueContinuously {
            sendActions(for: .valueChanged)
        }
        return true
    }

    /// end touch tracking, unlighlight two thumbs, and move to stepValue if needed
    override open func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        lowHandle.isHighlighted = false
        highHandle.isHighlighted = false
        if stepValue > 0 {
            stepValueInternal = stepValue
            setValue(low: lowValue, high: highValue, animated: true)
        }
        sendActions(for: .valueChanged)
    }

    // MARK: - class method to create image fast

    /// convert view to image
    @objc open func getImage(view: UIView) -> UIImage {
        UIGraphicsBeginImageContext(view.bounds.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let screenShot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenShot!
    }

    /// create a image with color
    @objc open func getImage(color: UIColor, size: CGSize) -> UIImage {
        let v = UIView()
        v.frame.size = size
        v.backgroundColor = color
        delegate?.rangeSliderWillDrawTrackImage(self, drawView: v)
        return getImage(view: v)
    }
}
