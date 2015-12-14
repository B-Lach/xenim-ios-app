//
//  TabBarController.swift
//  Listen
//
//  Created by Stefan Trauth on 14/12/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        PlayerManager.sharedInstance.baseViewController = self
    }

}
