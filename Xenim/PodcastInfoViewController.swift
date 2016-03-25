//
//  PodcastInfoViewController.swift
//  Xenim
//
//  Created by Stefan Trauth on 03/02/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit

class PodcastInfoViewController: UIViewController {
    
    weak var statusBarStyleDelegate: StatusBarDelegate!
    weak var pageViewDelegate: PageViewDelegate!
    
    var event: Event! {
        didSet {
            updateUI()
        }
    }

    @IBOutlet weak var podcastNameLabel: UILabel!
    @IBOutlet weak var coverartImageView: UIImageView!
    @IBOutlet weak var podcastDescriptionLabel: UILabel!
    @IBOutlet weak var toolbar: UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    func updateUI() {
        let placeholderImage = UIImage(named: "event_placeholder")!
        if let imageurl = event.podcast.artwork.originalUrl {
            coverartImageView?.af_setImageWithURL(imageurl, placeholderImage: placeholderImage, imageTransition: .CrossDissolve(0.2))
        }
        podcastNameLabel?.text = event.podcast.name
        podcastDescriptionLabel?.text = event.podcast.podcastDescription
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(animated: Bool) {
        statusBarStyleDelegate.updateStatusBarStyle(.LightContent)
    }
    
    @IBAction func backToPlayer(sender: AnyObject) {
        pageViewDelegate.showPage(0)
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
