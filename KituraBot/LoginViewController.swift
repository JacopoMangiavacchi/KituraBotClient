// Yi

import UIKit

class LoginViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        let navVC = segue.destination as! UINavigationController
        let chatVC = navVC.viewControllers.first as! ChatViewController
        
        chatVC.senderId = "jacopo"
        chatVC.senderDisplayName = "Jacopo" // chatVc.senderDisplayName is set to empty string, since this is an anonymous chat room.
    }
    
    
    
    @IBAction func loginDidTouch(_ sender: AnyObject) {
        
        self.performSegue(withIdentifier: "LoginToChat", sender: self)
        
    }
    
}

