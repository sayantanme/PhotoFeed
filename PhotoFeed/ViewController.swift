//
//  ViewController.swift
//  PhotoFeed
//
//  Created by Sayantan Chakraborty on 14/03/19.
//  Copyright © 2019 Sayantan Chakraborty. All rights reserved.
//

import Cocoa
import FirebaseCore
import RxSwift
import RxCocoa


class ViewController: NSViewController {
    
    @IBOutlet weak var collectionView: NSCollectionView!
    let vm = PViewerVM()
    let isRunning = BehaviorRelay<Bool>(value: true)
    let disBag = DisposeBag()
    var row = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FirebaseApp.configure()
        //        let storage = Storage.storage()
        //        print(storage.reference())
        
        // Do any additional setup after loading the view.
        vm.setupFirebase()
        
        _ = vm.photoModels.subscribe { (model) in
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
        self.setUpTimer()
        
        //vm.photoModels.asObservable().bind(to: collectionView.rx.ite)
    }
    
    fileprivate func setUpTimer(){
        isRunning.asObservable()
            .debug("isRunning")
            .flatMapLatest {  isRunning in
                isRunning ? Observable<Int>.interval(10, scheduler: MainScheduler.instance) : .empty()
            }
            .flatMap { int in Observable.just(index) }
            .debug("timer")
            .subscribe(onNext: { (val) in
                //let path = self.collectionView.indexPathsForVisibleItems().first
                if self.vm.photoItems.count > 0{
                    var nextIndex = Set<IndexPath>()
                    
                    self.row = self.row == self.vm.photoItems.count - 1 ? 0 : self.row + 1
                    
                    let nPath = IndexPath(item: self.row, section: 0)
                    nextIndex.insert(nPath)
                    print("Row:\(self.row),photoItems:\(self.vm.photoItems.count)")
                    
                    self.collectionView.scrollToItems(at: nextIndex, scrollPosition: NSCollectionView.ScrollPosition.centeredHorizontally)
                }
            }).disposed(by: disBag)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    
}
extension ViewController: NSCollectionViewDataSource{
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        //collectionView.rx.
        return vm.photoItems.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ImageViewer"), for: indexPath)
        guard let collectionViewItem = item as? ImageViewer else {return item}
        collectionViewItem.imageV.image = NSImage(contentsOf: vm.photoItems[indexPath.item].localUrl)
        return item
    }
    
    
}

