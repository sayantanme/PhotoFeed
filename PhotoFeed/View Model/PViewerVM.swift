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


class PViewerVM {
    
    private let disBag = DisposeBag()
    //let photoModels = BehaviorRelay<[PhotoModel]>(value: [])
    
    var photoItems = [PhotoModel]()
    
    
    func createImageStreams() -> PublishRelay<PhotoModel>{
        let models = PublishRelay<PhotoModel>()
        let localPhotoObs = getPhotoModelsFromLocalFolder()
        let firebasePhotos = getPhotoModelsFromFirebase().asObservable()
        
        Observable.of(localPhotoObs,firebasePhotos)
            .merge()
            .subscribe (onNext: { (model) in
                models.accept(model)
                self.photoItems.append(model)
            }).disposed(by: disBag)
        
        
        return models
        //self.photoItems.append(object)
    }
    
    fileprivate func getPhotoModelsFromLocalFolder() -> Observable<PhotoModel>{
        let photoLoaderDirec = URL(fileURLWithPath: "/Users/SayantanChakraborty/Documents/localPics", isDirectory: true)
        let urls = getFilesURLFromFolder(photoLoaderDirec)
        
        
        if let u = urls{
            let v = Observable.from(u).map { (url) -> PhotoModel in
                return PhotoModel(url: "", message: "", localUrl: url)
            }
            
            return v
        }
        
        return Observable<PhotoModel>.empty()
    }
    
    fileprivate func getPhotoModelsFromFirebase() -> PublishRelay<PhotoModel>{
        let photoModels = PublishRelay<PhotoModel>()
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
                    
                    let picDirectory = localPath.appendingPathComponent("\(NSDate().timeIntervalSince1970 * 1000).png", isDirectory: false)
                    
                    do{
                        try data.write(to: picDirectory)
                        
                    }catch{
                        print(error.localizedDescription)
                    }
                    return picDirectory
                })
                
                
                // Combines the two observable stream to create the PhotoModel. Then write to PublishRelay
                Observable.zip(
                    pModel, direc,
                    resultSelector: { value1, value2 -> PhotoModel in
                        //print("\(value1) \(value2)")
                        return PhotoModel(url: value1.last,message: value1.first,localUrl: value2)
                })
                .subscribe(onNext: { (object) in
                    print("Here:\(object)")
                    //self.photoItems.append(object)
                    photoModels.accept(object)
                }, onError: { (error) in
                    print(error.localizedDescription)
                }, onCompleted: {
                    print("Completed")
                })
                .disposed(by: self.disBag)

            }
        }
        return photoModels

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
    
    fileprivate func getFilesURLFromFolder(_ folderURL: URL) -> [URL]? {
        
        let options: FileManager.DirectoryEnumerationOptions =
            [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants]
        let fileManager = FileManager.default
        let resourceValueKeys = [URLResourceKey.isRegularFileKey, URLResourceKey.typeIdentifierKey]
        
        guard let directoryEnumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: resourceValueKeys,
                                                               options: options, errorHandler: { url, error in
                                                                print("`directoryEnumerator` error: \(error).")
                                                                return true
        }) else { return nil }
        
        var urls: [URL] = []
        for case let url as URL in directoryEnumerator {
            do {
                let resourceValues = try (url as NSURL).resourceValues(forKeys: resourceValueKeys)
                guard let isRegularFileResourceValue = resourceValues[URLResourceKey.isRegularFileKey] as? NSNumber else { continue }
                guard isRegularFileResourceValue.boolValue else { continue }
                guard let fileType = resourceValues[URLResourceKey.typeIdentifierKey] as? String else { continue }
                guard UTTypeConformsTo(fileType as CFString, "public.image" as CFString) else { continue }
                urls.append(url)
            }
            catch {
                print("Unexpected error occured: \(error).")
            }
        }
        return urls
    }
}
