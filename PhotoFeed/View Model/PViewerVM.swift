//
//  PViewerVM.swift
//  PhotoFeed
//
//  Created by Sayantan Chakraborty on 16/03/19.
//  Copyright © 2019 Sayantan Chakraborty. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import FirebaseDatabase
import FirebaseCore


struct PViewerVM {
    
    let disBag = DisposeBag()
    //let photoModels = BehaviorRelay<[PhotoModel]>(value: [])
    let photoModels = PublishRelay<PhotoModel>()
    
    func setupFirebase(){
        let dbRef = Database.database().reference()
        let localPath = createFolder()
        print(localPath)
        dbRef.observe(.childAdded) { (snap) in
            if let dSnaps = snap.children.allObjects as? [DataSnapshot]{
                
                // Fetches and creates array of url and comments to create Observable stream 1
                let snapshot = Observable.from(dSnaps)
                
                let pModel = snapshot.map({ (shot) -> String in
                    let v = "\(shot.value ?? "")"
                    return v
                })
                .buffer(timeSpan: 1, count: 2, scheduler: MainScheduler.instance)
                .filter({ (photoInfo) -> Bool in
                    return photoInfo.count == 0 ? false : true
                })

                // Creates the local URL observable and saves the file to a folder
                let direc = pModel.map({ model -> URLRequest in
                    return URLRequest(url: URL(string: model.last!)!)
                })
                .flatMap({ (request) -> Observable<(response:HTTPURLResponse, data:Data)> in
                    return URLSession.shared.rx.response(request: request)
                })
                .filter { (response, data)  in
                    return 200..<300 ~= response.statusCode
                }
                .map({ (_, data: Data) -> URL in
                    //var msg  = ""
                    
                    let picDirectory = localPath.appendingPathComponent("\(NSDate().timeIntervalSince1970 * 1000).png", isDirectory: false)
                    
                    do{
                        try data.write(to: picDirectory)
                        
                    }catch{
                        //msg = error.localizedDescription
                        print(error.localizedDescription)
                    }
                    return picDirectory
                })
                
                
                // Combines the two observable stream to create the PhotoModel. Then write to PublishRelay
                Observable.zip(
                    pModel, direc,
                    resultSelector: { value1, value2 -> PhotoModel in
                        //print("\(value1) \(value2)")
                        return PhotoModel(url: value1.first,message: value1.last,localUrl: value2)
                })
                .subscribe(onNext: { (object) in
                    print("Here:\(object)")
                    self.photoModels.accept(object)
                })
                .disposed(by: self.disBag)
            }
        }

    }
    
    fileprivate func createFolder() -> URL{
        let fileManager = FileManager.default
        var url = URL(string:"/Users/SayantanChakraborty/Desktop/PhotoAlbum")!
        //let fileManager = FileManager.default
        if let tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath =  tDocumentDirectory.appendingPathComponent("PhotoAlbum")
            if !fileManager.fileExists(atPath: filePath.path) {
                do {
                    try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    NSLog("Couldn't create document directory")
                }
            }
            NSLog("Document directory is \(filePath)")
            url = filePath
        }
        return url
    }
    
    fileprivate func downloadToLocalFile(){
        
    }
}
