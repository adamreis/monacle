
import AVFoundation
import MobileCoreServices
import MultipeerConnectivity
import UIKit

class SecondViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let connector = PeerConnector()
    @IBOutlet weak var sendVideoButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

//        connector.delegate = self
        connector.startAdvertisingToPeers()
        connector.startSearchForPeers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func sendVideoPressed(sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {

            var imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            imagePicker.mediaTypes = [kUTTypeMovie]
            imagePicker.allowsEditing = false

            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }


    // MARK: -
    // MARK: UIImagePickerControllerDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        println("Media selected")
        let movieURL = info[UIImagePickerControllerReferenceURL] as NSURL
        picker.dismissViewControllerAnimated(true, completion: nil)

        connector.sendVideo(movieURL)
    }

    // MARK: -
    // MARK: PeerConnectorDelegate

    func connector(connector: PeerConnector, didConnectToPeer peerID: MCPeerID) {
        sendVideoButton.enabled = true
    }

    func connector(connector: PeerConnector, didFinishVideoSend videoURL: NSURL) {

    }
}

