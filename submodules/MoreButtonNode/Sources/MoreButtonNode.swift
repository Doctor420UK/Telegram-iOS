import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData
import ManagedAnimationNode
import ContextUI

public final class MoreButtonNode: ASDisplayNode {
    public class MoreIconNode: ManagedAnimationNode {
        public enum State: Equatable {
            case more
            case search
        }
        
        private let encircled: Bool
        private let duration: Double = 0.21
        public var iconState: State = .search
        
        init(size: CGSize = CGSize(width: 30.0, height: 30.0), encircled: Bool) {
            self.encircled = encircled
            
            super.init(size: size)
            
            if self.encircled {
                self.trackTo(item: ManagedAnimationItem(source: .local("anim_moretosearch"), frames: .range(startFrame: 90, endFrame: 90), duration: 0.0))
            } else {
                self.iconState = .more
                self.trackTo(item: ManagedAnimationItem(source: .local("anim_baremoredots"), frames: .range(startFrame: 0, endFrame: 0), duration: 0.0))
            }
        }
            
        func play() {
            if case .more = self.iconState {
                let animationName = self.encircled ? "anim_moredots" : "anim_baremoredots"
                self.trackTo(item: ManagedAnimationItem(source: .local(animationName), frames: .range(startFrame: 0, endFrame: 46), duration: 0.76))
            }
        }
        
        public func enqueueState(_ state: State, animated: Bool) {
            guard self.iconState != state else {
                return
            }
            
            let previousState = self.iconState
            self.iconState = state
            
            let source = ManagedAnimationSource.local("anim_moretosearch")
            
            let totalLength: Int = 90
            if animated {
                switch previousState {
                    case .more:
                        switch state {
                            case .more:
                                break
                            case .search:
                                self.trackTo(item: ManagedAnimationItem(source: source, frames: .range(startFrame: 0, endFrame: totalLength), duration: self.duration))
                        }
                    case .search:
                        switch state {
                            case .more:
                                self.trackTo(item: ManagedAnimationItem(source: source, frames: .range(startFrame: totalLength, endFrame: 0), duration: self.duration))
                            case .search:
                                break
                        }
                }
            } else {
                switch state {
                    case .more:
                        self.trackTo(item: ManagedAnimationItem(source: source, frames: .range(startFrame: 0, endFrame: 0), duration: 0.0))
                    case .search:
                        self.trackTo(item: ManagedAnimationItem(source: source, frames: .range(startFrame: totalLength, endFrame: totalLength), duration: 0.0))
                }
            }
        }
    }

    public var action: ((ASDisplayNode, ContextGesture?) -> Void)?
    
    private let containerNode: ContextControllerSourceNode
    public let contextSourceNode: ContextReferenceContentNode
    private let buttonNode: HighlightableButtonNode
    public let iconNode: MoreIconNode
    
    private var color: UIColor?
    
    public var theme: PresentationTheme {
        didSet {
            self.update()
        }
    }
    private let size: CGSize
    
    public func updateColor(_ color: UIColor?, transition: ContainedViewLayoutTransition) {
        self.color = color
        
        if case let .animated(duration, curve) = transition {
            if let snapshotView = self.iconNode.view.snapshotContentTree() {
                snapshotView.frame = self.iconNode.frame
                self.view.addSubview(snapshotView)
                
                snapshotView.layer.animateAlpha(from: 1.0, to: 0.0, duration: duration, timingFunction: curve.timingFunction, removeOnCompletion: false, completion: { _ in
                    snapshotView.removeFromSuperview()
                })
                self.iconNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: duration, timingFunction: curve.timingFunction)
            }
        }
        self.update()
    }
    
    private func update() {
        let color = self.color ?? self.theme.rootController.navigationBar.buttonColor
        self.iconNode.customColor = color
    }
    
    public init(theme: PresentationTheme, size: CGSize = CGSize(width: 30.0, height: 30.0), encircled: Bool = true) {
        self.theme = theme
        self.size = size
        
        self.contextSourceNode = ContextReferenceContentNode()
        self.containerNode = ContextControllerSourceNode()
        self.containerNode.animateScale = false
        
        self.buttonNode = HighlightableButtonNode()
        self.iconNode = MoreIconNode(size: size, encircled: encircled)
        self.iconNode.customColor = self.theme.rootController.navigationBar.buttonColor
        
        super.init()
        
        self.addSubnode(self.buttonNode)
        
        self.buttonNode.addSubnode(self.containerNode)
        self.containerNode.addSubnode(self.contextSourceNode)
        self.contextSourceNode.addSubnode(self.iconNode)
        
        self.buttonNode.addTarget(self, action: #selector(self.buttonPressed), forControlEvents: .touchUpInside)
        
        self.containerNode.activated = { [weak self] gesture, _ in
            guard let strongSelf = self else {
                return
            }
            if case .more = strongSelf.iconNode.iconState {
                strongSelf.action?(strongSelf.contextSourceNode, gesture)
            }
        }
    }
    
    @objc public func buttonPressed() {
        self.action?(self.contextSourceNode, nil)
        if case .more = self.iconNode.iconState {
            self.iconNode.play()
        }
    }
        
    override public func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        let animationSize = self.size
        let inset: CGFloat = 0.0
        let iconFrame = CGRect(origin: CGPoint(x: inset + 6.0, y: floor((constrainedSize.height - animationSize.height) / 2.0) + 1.0), size: animationSize)
        
        self.iconNode.position = iconFrame.center
        self.iconNode.bounds = CGRect(origin: .zero, size: iconFrame.size)
        
        let size = CGSize(width: animationSize.width + inset * 2.0, height: constrainedSize.height)
        let bounds = CGRect(origin: CGPoint(), size: size)
        self.buttonNode.frame = bounds
        self.containerNode.frame = bounds
        self.contextSourceNode.frame = bounds
        return size
    }
}
