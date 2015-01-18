
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
    
    override init() {
        localPeerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.None)
        super.init()
        
        session.delegate = self
    }
    
    // MARK: -
    // MARK: MCSessionDelegate
    
    // Remote peer changed state
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        
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
        
    }
    
    // Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        
    }
}

class PeerServer: PeerConnector, MCNearbyServiceBrowserDelegate {
    var currentBrowser: MCNearbyServiceBrowser?
    var connectedPeers: [MCPeerID] = []
    
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
    }
    
    // MARK: -
    // MARK: MCNearbyServiceBrowserDelegate
    
    // Found a nearby advertising peer
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        println("PeerID found: \(peerID.displayName)")
        
        connectedPeers.append(peerID)
        
        browser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 30);
        syncWithClient(peerID)
        
        browser.stopBrowsingForPeers()
        currentBrowser = nil
    }
    
    // A nearby peer has stopped advertising
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        println("PeerID stopped broadcasting: \(peerID.displayName)")
    }
}

class PeerClient: PeerConnector, MCNearbyServiceAdvertiserDelegate {
    let advertizer: MCNearbyServiceAdvertiser
    
    override init() {
        let tempLocalPeer = MCPeerID(displayName: UIDevice.currentDevice().name)
        advertizer = MCNearbyServiceAdvertiser(peer: tempLocalPeer, discoveryInfo: nil, serviceType: serviceType)
        
        super.init()
        advertizer.delegate = self
    }
    
    deinit {
        advertizer.stopAdvertisingPeer()
    }
    
    func startAdvertisingPeer() {
        advertizer.startAdvertisingPeer()
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
