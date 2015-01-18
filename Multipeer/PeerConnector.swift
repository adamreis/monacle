
import AssetsLibrary
import AVFoundation
import Foundation
import MultipeerConnectivity

let serviceType = "sct-service"

enum PeerType : Int {
    case Server = 0
    case Client = 1
}

class PeerConnector: NSObject, MCSessionDelegate {
    let localPeerID: MCPeerID
    let session: MCSession
    var connectingPeers = NSMutableOrderedSet()
    var disconnectedPeers = NSMutableOrderedSet()
    weak var delegate: PeerConnectorDelegate?
    
    override init() {
        localPeerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.None)
        super.init()
        
        session.delegate = self
    }
    
    func connectedToPeer(peerID: MCPeerID) {
        // Meant to be overridden
    }
    
    func genTempExporterForVideo(assetURL: NSURL) -> AVAssetExportSession {
        let path = NSTemporaryDirectory().stringByAppendingPathComponent("tempVideo.mov")
        
        // Delete whatever was there originally
        let fileManager = NSFileManager.defaultManager()
        fileManager.removeItemAtPath(path, error: nil)
        
        let exporter = AVAssetExportSession(asset: AVAsset.assetWithURL(assetURL) as AVAsset, presetName: AVAssetExportPresetHighestQuality)
        exporter.outputURL = NSURL(fileURLWithPath: path)
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.shouldOptimizeForNetworkUse = false
        
        return exporter
    }
    
    // MARK: -
    // MARK: MCSessionDelegate
    
    // Remote peer changed state
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        
        println("Peer \(peerID) changed state: \(state.rawValue)")
        
        switch state {
        case .Connecting:
            connectingPeers.addObject(peerID)
            disconnectedPeers.removeObject(peerID)
        case .Connected:
            connectingPeers.removeObject(peerID)
            disconnectedPeers.removeObject(peerID)
            
            connectedToPeer(peerID)
            
        case .NotConnected:
            connectingPeers.removeObject(peerID)
            disconnectedPeers.addObject(peerID)
        }
    }
    
    // Received data from remote peer
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        println("Got data: \(data)")
    }
    
    // Received a byte stream from remote peer
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        
    }
    
    // Start receiving a resource from remote peer
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        println("didStartReceivingResource Video")
    }
    
    // Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        if error != nil {
            println("Session saving error: \(error)")
            return
        }
        
        let fileManager = NSFileManager()
        let newURL = NSURL(string: resourceName, relativeToURL: localURL.URLByDeletingLastPathComponent)!
        
        // Delete whatever was there originally
        fileManager.removeItemAtURL(newURL, error: nil)
        
        fileManager.moveItemAtURL(localURL, toURL: newURL, error: nil)
        
        let assetsLibrary = ALAssetsLibrary()
        if assetsLibrary.videoAtPathIsCompatibleWithSavedPhotosAlbum(newURL) {
            assetsLibrary.writeVideoAtPathToSavedPhotosAlbum(newURL, completionBlock: { (newlySavedURL: NSURL!, error: NSError!) -> Void in
                println("Video save complete")
            })
        } else {
            println("Video not compatible")
        }
    }
}

class PeerServer: PeerConnector, MCNearbyServiceBrowserDelegate {
    var currentBrowser: MCNearbyServiceBrowser?
    
    override init() {
        super.init()
    }
    
    func createBrowserViewController() -> MCBrowserViewController {
        let browser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceType)
        let browserViewController = MCBrowserViewController(browser: browser, session: session)
        browserViewController.minimumNumberOfPeers = 2
        browserViewController.maximumNumberOfPeers = 2
        
        return browserViewController
    }
    
    func connectToClient() {
        if currentBrowser == nil {
            currentBrowser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceType)
            currentBrowser!.delegate = self
        }
        
        println("Started browsing for peers")
        currentBrowser?.startBrowsingForPeers()
    }
    
    func syncWithClient(peerID: MCPeerID) {
        // TODO - Sync timing
        let data = "Hello, World!".dataUsingEncoding(NSUTF8StringEncoding)
        var error: NSError?
        
        if !session.sendData(data, toPeers: [peerID], withMode: MCSessionSendDataMode.Reliable, error: &error) {
            println("Sync Error: \(error)")
        }
        
        println("Sync complete")
        
        delegate?.connector(self, didConnectToPeer: peerID)
    }
    
    func sendVideo(assetURL: NSURL) {
        let clientID = getOneClientID()
        
        let exporter = genTempExporterForVideo(assetURL)
        
        exporter.exportAsynchronouslyWithCompletionHandler { () -> Void in
            let videoURL = exporter.outputURL
            println("Sending \(videoURL) to \(clientID.displayName)")
            
            self.session.sendResourceAtURL(videoURL, withName: NSUUID().UUIDString + ".mov", toPeer: clientID)
                { [unowned self] (error: NSError!) -> Void in
                    if error != nil {
                        println("Sending error: \(error)")
                        return
                    }
                    println("Video send completed")
                    self.delegate?.connector(self, didFinishVideoSend: videoURL)
            }
        }
    }
    
    func getOneClientID() -> MCPeerID {
        return session.connectedPeers.last as MCPeerID
    }
    
    override func connectedToPeer(peerID: MCPeerID) {
        syncWithClient(peerID)
    }
    
    // MARK: -
    // MARK: MCNearbyServiceBrowserDelegate
    
    // Found a nearby advertising peer
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        if peerID.displayName == localPeerID.displayName {
            return
        }
        println("PeerID found: \(peerID.displayName)")
        
        browser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 30);
        
        browser.stopBrowsingForPeers()
        currentBrowser = nil
    }
    
    // A nearby peer has stopped advertising
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        println("PeerID stopped broadcasting: \(peerID.displayName)")
    }
}

class PeerClient: PeerConnector {
    var assistant: MCAdvertiserAssistant?
    
    override init() {
        let tempLocalPeer = MCPeerID(displayName: UIDevice.currentDevice().name)
        
        super.init()
        
        assistant = MCAdvertiserAssistant(serviceType: serviceType, discoveryInfo: nil, session: session)
    }
    
    deinit {
        assistant!.stop()
    }
    
    func startAdvertisingPeer() {
        assistant!.start()
        println("Advertising started")
    }
    
    // MARK: -
    // MARK: MCNearbyServiceAdvertiserDelegate
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {

        println("Accepted invitation from peer: \(peerID)")
        
        invitationHandler(true, session)
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        println("Advertising error : \(error)")
    }
}

protocol PeerConnectorDelegate: NSObjectProtocol {
    func connector(connector: PeerConnector, didConnectToPeer peerID: MCPeerID)
    
    func connector(connector: PeerConnector, didFinishVideoSend videoURL: NSURL)
}
