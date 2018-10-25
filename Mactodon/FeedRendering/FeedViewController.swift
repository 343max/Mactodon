// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit

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
