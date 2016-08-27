//
//  uDList.swift
//  word
//
//  Created by Andy Feng on 8/22/16.
//  Copyright © 2016 Andy Feng. All rights reserved.
//

import UIKit

class uDList {
    
    var defid: Int
    var word: String
    var author: String
    var permalink: String
    var definition: String
    var example: String
    var thumbs_up: Int
    var thumbs_down: Int
    var score: Int
    

    
    init(defid: Int, word: String, author: String, permalink: String, definition: String, example: String, thumbs_up: Int, thumbs_down: Int){
        self.defid = defid
        self.word = word
        self.author = author
        self.permalink = permalink
        self.definition = definition
        self.example = example
        self.thumbs_up = thumbs_up
        self.thumbs_down = thumbs_down
        self.score = thumbs_up - thumbs_down
    }
    
}