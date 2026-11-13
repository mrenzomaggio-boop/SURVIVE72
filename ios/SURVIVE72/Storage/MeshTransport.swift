import Foundation
import MultipeerConnectivity

/// The link to nearby phones, hidden behind a protocol so the mesh can be
/// tested without radios. Peers are named by an opaque token.
protocol MeshTransport: AnyObject {
    var delegate: MeshTransportDelegate? { get set }
    var connectedPeers: [String] { get }
    func start()
    func stop()
    func send(_ data: Data, to peer: String)
}

/// Events from the transport. Always delivered on the main thread.
protocol MeshTransportDelegate: AnyObject {
    func meshTransport(peerConnected peer: String)
    func meshTransport(peerDisconnected peer: String)
    func meshTransport(didReceive data: Data, from peer: String)
}

/// What two phones say to each other when they meet.
enum MeshWire: Codable, Equatable {
    /// "These are the packets I already have": the other phone sends the rest.
    /// It also carries who is on this phone, signed, so phones next to each
    /// other see each other at once. Older versions send no card.
    case hello(known: [UUID], card: MeshCard? = nil, signature: Data? = nil)
    case packets([MeshPacket])

    /// Packets per message, to keep each transfer small.
    static let batchSize = 20

    func encoded() -> Data? { try? JSONEncoder().encode(self) }

    static func decoded(_ data: Data) -> MeshWire? {
        // Refuse oversized input before parsing it.
        guard data.count <= 512 * 1024 else { return nil }
        return try? JSONDecoder().decode(MeshWire.self, from: data)
    }

    static func batches(_ packets: [MeshPacket]) -> [MeshWire] {
        stride(from: 0, to: packets.count, by: batchSize).map {
            .packets(Array(packets[$0..<min($0 + batchSize, packets.count)]))
        }
    }
}

/// Real phone-to-phone link over Bluetooth and peer-to-peer Wi-Fi
/// (Apple MultipeerConnectivity). No internet and no server are involved.
/// Works between iPhones that have the app open and are near each other.
final class MultipeerTransport: NSObject, MeshTransport {
    /// Bonjour service name; must match NSBonjourServices in Info.plist.
    static let serviceType = "survive72-mesh"

    weak var delegate: MeshTransportDelegate?

    private var localPeer: MCPeerID?
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    /// Connected peers by token. Touched only on the main thread.
    private var peers: [String: MCPeerID] = [:]

    var connectedPeers: [String] { Array(peers.keys) }

    func start() {
        guard session == nil else { return }
        // A random token per start: the radio name reveals nothing about the user.
        let peer = MCPeerID(displayName: UUID().uuidString)
        let session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        let advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil,
                                                   serviceType: MultipeerTransport.serviceType)
        advertiser.delegate = self
        let browser = MCNearbyServiceBrowser(peer: peer, serviceType: MultipeerTransport.serviceType)
        browser.delegate = self

        localPeer = peer
        self.session = session
        self.advertiser = advertiser
        self.browser = browser
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        advertiser = nil
        browser = nil
        session = nil
        localPeer = nil
        let lost = Array(peers.keys)
        peers.removeAll()
        for peer in lost { delegate?.meshTransport(peerDisconnected: peer) }
    }

    func send(_ data: Data, to peer: String) {
        guard let session, let target = peers[peer] else { return }
        try? session.send(data, toPeers: [target], with: .reliable)
    }
}

extension MultipeerTransport: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self, session === self.session else { return }
            let token = peerID.displayName
            switch state {
            case .connected:
                self.peers[token] = peerID
                self.delegate?.meshTransport(peerConnected: token)
            case .notConnected:
                if self.peers.removeValue(forKey: token) != nil {
                    self.delegate?.meshTransport(peerDisconnected: token)
                }
            default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            guard let self, session === self.session else { return }
            self.delegate?.meshTransport(didReceive: data, from: peerID.displayName)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String,
                 fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, with progress: Progress) {}

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerTransport: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Every phone with the app may join: packets are signed and checked one by one.
        invitationHandler(session != nil, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {}
}

extension MultipeerTransport: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String: String]?) {
        guard let session, let localPeer else { return }
        // Both phones see each other: only the one with the smaller token invites.
        if localPeer.displayName < peerID.displayName {
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 20)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {}
}
