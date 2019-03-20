//
//  ViewController.swift
//  PhotoFeed
//
//  Created by Sayantan Chakraborty on 14/03/19.
//  Copyright © 2019 Sayantan Chakraborty. All rights reserved.
//

import Cocoa
import FirebaseCore


class ViewController: NSViewController {

    let vm = PViewerVM()
    override func viewDidLoad() {
        super.viewDidLoad()
        FirebaseApp.configure()
//        let storage = Storage.storage()
//        print(storage.reference())

        // Do any additional setup after loading the view.
        vm.setupFirebase()
        
        _ = vm.photoModels.subscribe { (model) in
            print("Models are:\(model.element)")
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

