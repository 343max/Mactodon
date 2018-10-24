// Copyright Max von Webel. All Rights Reserved.

import Cocoa
import MastodonKit

class FeedViewController: NSViewController {
  let client: ValuePromise<Client?>
  var timeline = ValuePromise<[Status]>(initialValue: [])
  var collectionView: NSCollectionView!
  
  override func loadView() {
    self.view = NSView()
  }
  
  init(client: ValuePromise<Client?>) {
    self.client = client
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    let collectionView = NSCollectionView(frame: view.bounds)
    view.addSubview(collectionView)
    collectionView.delegate = self
    collectionView.dataSource = self
    
    collectionView.register(ToothView.self, forItemWithIdentifier: ToothView.identifier)
    
    self.collectionView = collectionView
    
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

class ToothView: NSView {
  static let identifier = NSUserInterfaceItemIdentifier("ToothView")
}

extension FeedViewController: NSCollectionViewDataSource {
  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    return 0
  }
  
  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    let item = collectionView.makeItem(withIdentifier: ToothView.identifier, for: indexPath)
    return item
  }
  
  
}
