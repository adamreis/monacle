
import AssetsLibrary
import AVFoundation
import Foundation
import MultipeerConnectivity

let serviceType = "sct-service"

enum PeerType : Int {
    case Server = 0
    case Client = 1
}

enum MessageTypes: String {
    case StartRecording = "Start"
    case StopRecording = "Stop"
}

class PeerConnector: NSObject, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    let localPeerID: MCPeerID
    let session: MCSession
    
    var currentBrowser: MCNearbyServiceBrowser?
    weak var delegate: PeerConnectorDelegate?
    
    var assistant: MCAdvertiserAssistant?
    let sessionManager: PeerSessionManager
    
    override init() {
        localPeerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.None)
        assistant = MCAdvertiserAssistant(serviceType: serviceType, discoveryInfo: nil, session: session)
        
        sessionManager = PeerSessionManager(fromSession: session)
        
        super.init()
        
        sessionManager.parentConnector = self
    }
    
    deinit {
        assistant!.stop()
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
    // MARK: Sending methods
    
    func startSearchForPeers() {
        if currentBrowser == nil {
            currentBrowser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceType)
            currentBrowser!.delegate = self
        }
        
        println("Started browsing for peers")
        currentBrowser!.startBrowsingForPeers()
    }
    
    func stopSearchingForPeers() {
        currentBrowser?.stopBrowsingForPeers()
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
    
    func sendSignal(peerID: MCPeerID, messageType: MessageTypes) {
        println("Sending signal \(messageType.rawValue) to \(peerID.displayName)")
        let rootObject: [String: String] = ["type": messageType.rawValue]
        let data = NSKeyedArchiver.archivedDataWithRootObject(rootObject)
        
        messageType.rawValue
        var error: NSError?
        
        if !session.sendData(data, toPeers: [peerID], withMode: MCSessionSendDataMode.Reliable, error: &error) {
            println("Sync Error: \(error)")
        }
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
    
    func connectedToPeer(peerID: MCPeerID) {
//        syncWithClient(peerID)
        delegate?.connector(self, didConnectToPeer: peerID)
    }
    
    // MARK: -
    // MARK: Listening methods
    
    func startAdvertisingToPeers() {
        assistant!.start()
        println("Advertising started")
    }
    
    func peerCountChanged(newCount: Int) {
        if newCount >= 2 {
            stopSearchingForPeers()
        } else {
            startSearchForPeers()
        }
    }
    
    func saveVideo(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        
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
                
                self.delegate?.connector(self, didFinishVieoRecieve: newlySavedURL)
            })
        } else {
            println("Video not compatible")
        }
        
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

class PeerSessionManager: NSObject, MCSessionDelegate {
    var connectingPeers = NSMutableOrderedSet()
    var disconnectedPeers = NSMutableOrderedSet()
    let session: MCSession
    weak var parentConnector: PeerConnector?
    
    init(fromSession session: MCSession) {
        self.session = session
        
        super.init()
        
        session.delegate = self
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
            
            parentConnector?.connectedToPeer(peerID)
            
        case .NotConnected:
            connectingPeers.removeObject(peerID)
            disconnectedPeers.addObject(peerID)
        }
        
        let totalCount = session.connectedPeers.count + connectingPeers.count
        parentConnector?.peerCountChanged(totalCount)
    }
    
    // Received data from remote peer
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        println("Got data: \(data)")
        
        let dict = NSKeyedUnarchiver.unarchiveObjectWithData(data) as [String: String]
        let signalType = MessageTypes(rawValue: dict["type"]!)!
        
        parentConnector?.delegate?.receivedSignal(signalType)
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
        parentConnector?.saveVideo(session, didFinishReceivingResourceWithName: resourceName, fromPeer: peerID, atURL: localURL, withError: error)
    }
}

protocol PeerConnectorDelegate: NSObjectProtocol {
    func connector(connector: PeerConnector, didConnectToPeer peerID: MCPeerID)
    
    func connector(connector: PeerConnector, didFinishVideoSend videoURL: NSURL)
    
    func connector(connector: PeerConnector, didFinishVieoRecieve videoURL: NSURL)
    
    func receivedSignal(signalType: MessageTypes)
}
