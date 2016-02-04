//
//  PodcastInfoViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 03/02/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit

class PodcastInfoViewController: UIViewController {
    
    var statusBarStyleDelegate: StatusBarDelegate!
    var pageViewDelegate: PageViewDelegate!
    
    var event: Event!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "< Player", style: UIBarButtonItemStyle.Plain, target: self, action: "backToPlayer:")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(animated: Bool) {
        statusBarStyleDelegate.updateStatusBarStyle(.Default)
    }
    
    func backToPlayer(sender: AnyObject) {
        pageViewDelegate.showPage(1)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
