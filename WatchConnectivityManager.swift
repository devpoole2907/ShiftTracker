//
//  WatchConnectivityManager.swift
//  ShiftTracker
//
//  Created by James Poole on 25/04/23.
//

import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var receivedJobs: [JobData] = []
    
    private override init(){
        super.init()
        
        if WCSession.isSupported() {
                    WCSession.default.delegate = self
                    WCSession.default.activate()
                }
        
    }
    
    
    func sendJobData(_ jobs: [Job]) {
        print("Sending jobs data to watchOS app...")
        let jobDataArray = jobs.map { jobData(from: $0) }
        if WCSession.default.isReachable {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(jobDataArray)
                WCSession.default.sendMessageData(data, replyHandler: nil, errorHandler: { error in
                    print("Error sending data: \(error.localizedDescription)")
                })
            } catch {
                print("Error encoding data: \(error.localizedDescription)")
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode([JobData].self, from: messageData)
            DispatchQueue.main.async {
                self.receivedJobs = decodedData
            }
        } catch {
            print("Error decoding data: \(error.localizedDescription)")
        }
    }
    
    



    
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
