//
//  HelperExtensions.swift
//  Xenim
//
//  Created by Stefan Trauth on 08/08/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import Foundation

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}
