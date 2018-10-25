// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit
import Nuke


class TootCollectionViewItem: NSCollectionViewItem {
  static let identifier = NSUserInterfaceItemIdentifier("TootCollectionViewItem")
  
  var usernameField: NSTextField!
  var tootField: NSTextField!
  var avatarView: NSImageView!
  var status: Status? {
    didSet {
      guard let status = status else {
        usernameField.attributedStringValue = NSAttributedString(string: "")
        tootField.attributedStringValue = NSAttributedString(string: "")
        avatarView.image = nil
        return
      }
      
      usernameField.set(html: "<displayName>\(status.account.displayName)</displayName> <username><at>@</at>\(status.account.username)</username>")
      tootField.set(html: status.content)
    }
  }
  
  class FlippedView: NSView {
    override var isFlipped: Bool {
      get {
        return true
      }
    }
  }
  
  override func loadView() {
    view = FlippedView()
  }
  
  func textField() -> NSTextField {
    let field = NSTextField(frame: .zero)
    field.isEditable = false
    field.isBordered = false
    field.backgroundColor = NSColor.clear
    return field
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tootField = textField()
    view.addSubview(tootField)
    
    usernameField = textField()
    usernameField.cell?.lineBreakMode = .byTruncatingTail
    view.addSubview(usernameField)
    
    avatarView = NSImageView(frame: .zero)
    avatarView.wantsLayer = true
    avatarView.layer!.cornerRadius = 6
    avatarView.layer!.masksToBounds = true
    
    view.addSubview(avatarView)
  }
  
  override func viewWillAppear() {
    super.viewWillAppear()
    
    guard let status = status else {
      return
    }
    
    Nuke.loadImage(with: URL(string: status.account.avatar)!, into: avatarView!)
  }
  
  override func viewDidLayout() {
    super.viewDidLayout()
    
    layout(width: collectionView!.bounds.width)
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    status = nil
  }
  
  @discardableResult func layout(width: CGFloat) -> NSSize {
    let inset = NSEdgeInsets(top: 10, left: 5, bottom: 15, right: 15)
    let imageSideLenght: CGFloat = 48
    let imageSpace: CGFloat = 10
    let textFieldSpace: CGFloat = 3
    
    let imageFrame = NSRect(x: inset.left, y: inset.top, width: imageSideLenght, height: imageSideLenght)
    avatarView.frame = imageFrame
    
    let textLeft = imageFrame.maxX + imageSpace
    let textWidth = width - textLeft - inset.right
    
    let textfieldSize = NSSize(width: textWidth, height: 0)
    let usernameFrame = NSRect(origin: CGPoint(x: textLeft, y: inset.top), size: usernameField.sizeThatFits(textfieldSize))
    usernameField.frame = usernameFrame
    
    let tootFrame = NSRect(origin: CGPoint(x: textLeft, y: usernameFrame.maxY + textFieldSpace), size: tootField.sizeThatFits(textfieldSize))
    tootField.frame = tootFrame
    
    return CGSize(width: width, height: max(tootFrame.maxY, imageFrame.maxY) + inset.bottom)
  }
}

class FeedViewController: NSViewController {
  private let client: ValuePromise<Client?>
  private var timeline = ValuePromise<[Status]>(initialValue: [])
  private var scrollView: NSScrollView!
  private var collectionView: NSCollectionView!
  
  class Layout: NSCollectionViewFlowLayout {
    override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
      if (newBounds.width == collectionViewContentSize.width) {
        return false
      }
      
      invalidateLayout()
      return true
    }
  }
  
  override func loadView() {
    let collectionView = NSCollectionView(frame: .zero)
    collectionView.delegate = self
    collectionView.autoresizingMask = [.width, .height]
    let layout = Layout()
    layout.minimumLineSpacing = 1
    layout.minimumInteritemSpacing = 0
    collectionView.collectionViewLayout = layout
    collectionView.dataSource = self
    
    collectionView.register(TootCollectionViewItem.self, forItemWithIdentifier: TootCollectionViewItem.identifier)
    
    self.collectionView = collectionView
    
    let scrollView = NSScrollView(frame: .zero)
    scrollView.documentView = collectionView
    self.scrollView = scrollView
    self.view = scrollView
  }
  
  init(client: ValuePromise<Client?>) {
    self.client = client
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    client.didSet.mainQueue.then { [weak self] in
      self?.reload()
    }
    
    timeline.didSet.mainQueue.then { [weak self] in
      self?.collectionView.reloadData()
    }
  }
  
  func reload() {
    client.value?.run(Timelines.home()).then { [weak self] (timeline) in
      self?.timeline.value = timeline
    }
  }
}

extension FeedViewController: NSCollectionViewDelegate {
  
}

extension FeedViewController: NSCollectionViewDataSource {
  static var sizingTootView: TootCollectionViewItem = {
    let item = TootCollectionViewItem(nibName: nil, bundle: nil)
    let _ = item.view
    return item
  }()
  
  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    return timeline.value.count
  }
  
  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    let item = collectionView.makeItem(withIdentifier: TootCollectionViewItem.identifier, for: indexPath) as! TootCollectionViewItem
    item.status = timeline.value[indexPath.item]
    return item
  }
}

extension FeedViewController: NSCollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
    let item = FeedViewController.sizingTootView
    item.status = timeline.value[indexPath.item]
    return item.layout(width: collectionView.bounds.width)
  }
}
