import UIKit
import MultipeerConnectivity

class SecondViewController: UIViewController, MCBrowserViewControllerDelegate {
    let client = PeerClient()
    var server: PeerServer?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        client.startAdvertisingPeer()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func connectButtonTouched(sender: UIButton) {
        if server == nil {
            server = PeerServer()
        }
        let browserViewController = server!.createBrowserViewController()
        browserViewController.delegate = self
        
        self.presentViewController(browserViewController, animated: true, completion: nil)
    }
    
    // MARK: -
    // MARK: MCBrowserViewControllerDelegate
    
    // Notifies the delegate, when the user taps the done button
    func browserViewControllerDidFinish(browserViewController: MCBrowserViewController!) {
        browserViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Notifies delegate that the user taps the cancel button.
    func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController!) {
        browserViewController.dismissViewControllerAnimated(true) {
            println("Animation canceled")
        }
    }
}

