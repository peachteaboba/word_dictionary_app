//
//  Definition.swift
//  word
//
//  Created by Andy Feng on 8/21/16.
//  Copyright © 2016 Andy Feng. All rights reserved.
//

import UIKit

class Definition {
    
    var type: String
    var definition: String
    var example: String

    init(type: String, definition: String, example: String){
        self.type = type
        self.definition = definition
        self.example = example
    }
    
}

