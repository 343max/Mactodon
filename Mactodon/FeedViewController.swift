// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit


class TootView: NSCollectionViewItem {
  static let identifier = NSUserInterfaceItemIdentifier("TootView")
  
  var usernameField: NSTextField!
  var tootField: NSTextField!
  
  class View: NSView {
    override var isFlipped: Bool {
      get {
        return true
      }
    }
  }
  
  override func loadView() {
    view = View()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.orange.cgColor
  }
  
  func textField() -> NSTextField {
    let field = NSTextField(frame: .zero)
    field.isEditable = false
    return field
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tootField = textField()
    view.addSubview(tootField)
  }
  
  override func viewDidLayout() {
    super.viewDidLayout()
    
    layout()
  }
  
  @discardableResult func layout() -> NSSize {
    let width = collectionView!.bounds.width
    let textWidth = width
    tootField.frame = NSRect(origin: .zero, size: tootField.sizeThatFits(NSSize(width: textWidth, height: 0)))
    return tootField.frame.size
  }
}

class FeedViewController: NSViewController {
  let client: ValuePromise<Client?>
  var timeline = ValuePromise<[Status]>(initialValue: [])
  var scrollView: NSScrollView!
  var collectionView: NSCollectionView!
  
  class Layout: NSCollectionViewFlowLayout {
    override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
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
    
    collectionView.register(TootView.self, forItemWithIdentifier: TootView.identifier)
    
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
  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    return timeline.value.count
  }
  
  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    let item = collectionView.makeItem(withIdentifier: TootView.identifier, for: indexPath) as! TootView
    let status = timeline.value[indexPath.item]
    item.tootField.set(html: status.content)
    return item
  }
}

extension FeedViewController: NSCollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
    return NSSize(width: collectionView.bounds.width, height: 100)
  }
}
