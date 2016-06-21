//
//  GlobalSplitViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 21/06/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import Foundation

import UIKit

class GlobalSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
    }
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool{
        return true
    }
    
}