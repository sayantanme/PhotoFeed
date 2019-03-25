//
//  ImageViewer.swift
//  PhotoFeed
//
//  Created by Sayantan Chakraborty on 23/03/19.
//  Copyright © 2019 Sayantan Chakraborty. All rights reserved.
//

import Cocoa

class ImageViewer: NSCollectionViewItem {

    // 1
    @IBOutlet weak var imageV: NSImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.view.layer?.backgroundColor = NSColor.yellow.cgColor
    }
    
}
