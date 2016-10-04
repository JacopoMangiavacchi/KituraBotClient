//
//  IntentViewController.swift
//  KituraBotSiriExtensionUI
//
//  Created by Jacopo Mangiavacchi on 10/3/16.
//  Copyright © 2016 Jacopo. All rights reserved.
//

import IntentsUI

// As an example, this extension's Info.plist has been configured to handle interactions for INSendMessageIntent.
// You will want to replace this or add other intents as appropriate.
// The intents whose interactions you wish to handle must be declared in the extension's Info.plist.

// You can test this example integration by saying things to Siri like:
// "Send a message using <myApp>"

class IntentViewController: UIViewController, INUIHostedViewControlling, INUIHostedViewSiriProviding {
    
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - INUIHostedViewControlling
    
    // Prepare your view controller for the interaction to handle.
    func configure(with interaction: INInteraction!, context: INUIHostedViewContext, completion: ((CGSize) -> Void)!) {
        // Do configuration here, including preparing views and calculating a desired size for presentation.
        var size: CGSize
        
        //label.text = interaction.messageContent
        
        if let intent = interaction.intent as? INSendMessageIntent {
            label.text = intent.content
            
            //            switch interaction.intentHandlingStatus {
            //            case .unspecified, .inProgress, .ready, .failure:
            //                chatViewController.isSent = false
            //
            //            case .done, .deferredToApplication:
            //                chatViewController.isSent = true
            //            }
            
            size = desiredSize
        }
        else {
            // Otherwise, we'll tell the host to draw us at zero size.
            size = desiredSize // CGSize.zero
        }
        
        
        if let completion = completion {
            completion(size)
        }
    }
    
    var desiredSize: CGSize {
        return self.extensionContext!.hostedViewMaximumAllowedSize
    }
    
    var displaysMessage: Bool {
        return true
    }
}
