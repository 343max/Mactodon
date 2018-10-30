// Copyright Max von Webel. All Rights Reserved.

import Cocoa

protocol PullToRefreshCellDelegate: AnyObject {
  func startRefresh()
}

class PullToRefreshCell: NSCollectionViewItem, FeedViewCell {
  static let identifier = NSUserInterfaceItemIdentifier("PullToRefreshCell")
  
  weak var delegate: PullToRefreshCellDelegate?
  private var progressIndicator: NSProgressIndicator!
  
  var refreshing = false {
    didSet {
      progressIndicator.isIndeterminate = refreshing
      if refreshing {
        progressIndicator.startAnimation(nil)
        delegate?.startRefresh()
      }
    }
  }
  
  private let pullDistance = CGFloat(50)
  
  func willDisplay() {
    progressIndicator.startAnimation(nil)
    NotificationCenter.default.addObserver(self, selector: #selector(boundsDidChange(_:)), name: NSView.boundsDidChangeNotification, object: collectionView!.superview)
  }
  
  func didEndDisplaying() {
    progressIndicator.stopAnimation(nil)
    NotificationCenter.default.removeObserver(self)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  static func size(width: CGFloat, isReloading: Bool) -> CGSize {
    let height: CGFloat = isReloading ? 40 : 0
    return CGSize(width: width, height: height)
  }
  
  @objc func boundsDidChange(_ notification: Notification) {
    if refreshing {
      return
    }
    
    let scrollView = (notification.object as! NSView).superview as! NSScrollView
    
    let y = 0.0 - scrollView.documentVisibleRect.minY
    if y < 0 {
      return
    }
    
    refreshing = y > pullDistance
    
    progressIndicator.doubleValue = Double(y)
  }
  
  override func loadView() {
    view = NSView()
    view.wantsLayer = true
    view.layer!.masksToBounds = false
  }
  
  override func viewDidLayout() {
    super.viewDidLayout()
    self.layout(width: self.view.bounds.width)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    progressIndicator = NSProgressIndicator(frame: .zero)
    progressIndicator.isIndeterminate = false
    progressIndicator.isDisplayedWhenStopped = true
    progressIndicator.style = .bar
    progressIndicator.minValue = 15
    progressIndicator.maxValue = Double(pullDistance)
    view.addSubview(progressIndicator)
  }
  
  func layout(width: CGFloat) {
    let size = CGSize(width: round(width / 3.0), height: 12)
    let origin = CGPoint(x: round(width / 3.0), y: 10)
    progressIndicator.frame = CGRect(origin: origin, size: size)
    progressIndicator.sizeToFit()
  }
}
