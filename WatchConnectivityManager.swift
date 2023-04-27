//
//  WatchConnectivityManager.swift
//  ShiftTracker
//
//  Created by James Poole on 25/04/23.
//

import Foundation
import WatchConnectivity
import CoreData

final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    let persistenceController = PersistenceController.shared
    
    var onDeleteJob: ((UUID) -> Void)?

    
    @Published var receivedJobs: [JobData] = []
    
    private override init(){
        super.init()
        
        if WCSession.isSupported() {
                    WCSession.default.delegate = self
                    WCSession.default.activate()
            print("watch session is supported")
                }
        
    }
    
    
    func sendJobData(_ jobs: [Job]) {
        print("Sending jobs data to watchOS app...")
        let jobDataArray = jobs.map { jobData(from: $0) }
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(jobDataArray)
            let userInfo = ["action": "updateJobs", "jobsData": data] as [String: Any]
            WCSession.default.transferUserInfo(userInfo)
            print("job data has been transferred from the ios app")
        } catch {
            print("Error encoding data: \(error.localizedDescription)")
        }
    }

    /*
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
           let decoder = JSONDecoder()
           do {
               let decodedData = try decoder.decode([JobData].self, from: messageData)
               saveReceivedJobsToCoreData(decodedData)
           } catch {
               print("Error decoding data: \(error.localizedDescription)")
           }
       } */
    
    private func saveReceivedJobsToCoreData(_ jobs: [JobData]) {
            let context = persistenceController.container.viewContext

            jobs.forEach { jobData in
                let job = Job(context: context)
                job.name = jobData.name
                job.title = jobData.title
                job.hourlyPay = jobData.hourlyPay
                job.colorRed = jobData.colorRed
                job.colorGreen = jobData.colorGreen
                job.colorBlue = jobData.colorBlue
                job.uuid = jobData.id
  
            }

            do {
                try context.save()
                DispatchQueue.main.async {
                    self.receivedJobs = jobs
                }
            } catch {
                print("Failed to save received jobs to Core Data: \(error.localizedDescription)")
            }
        }
    
    // watchos delete job function
    func deleteJob(_ job: Job) {
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(["action": "deleteJob", "jobId": job.uuid?.uuidString ?? UUID()], replyHandler: nil) { error in
                    print("Error sending deleteJob message: \(error.localizedDescription)")
                }
            }
        }
    
    // send delete message to watch
    #if os(iOS)
    func sendDeleteJobMessage(_ jobId: UUID) {
        let userInfo = ["action": "deleteJob", "jobId": jobId.uuidString]
        WCSession.default.transferUserInfo(userInfo)
    }

    #endif
    // recieve message
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        if let action = userInfo["action"] as? String {
            if action == "deleteJob", let jobIdString = userInfo["jobId"] as? String {
                if let jobId = UUID(uuidString: jobIdString) {
                    let context = persistenceController.container.viewContext
                    deleteJob(with: jobId, in: context)
                }
            } else if action == "updateJobs", let jobsData = userInfo["jobsData"] as? Data {
                let decoder = JSONDecoder()
                do {
                    let decodedData = try decoder.decode([JobData].self, from: jobsData)
                    saveReceivedJobsToCoreData(decodedData)
                } catch {
                    print("Error decoding data: \(error.localizedDescription)")
                }
            }
        }
    }



    
    // need delete job here for ios version
    
    
    func deleteJob(with jobId: UUID, in context: NSManagedObjectContext) {
        guard let job = fetchJob(with: jobId, in: context) else {
            return
        }

        context.delete(job)
        do {
            try context.save()
        } catch {
            print("Failed to delete job: \(error.localizedDescription)")
        }
    }

    
    
    
    private func fetchJob(with jobId: UUID, in context: NSManagedObjectContext) -> Job? {
        let fetchRequest: NSFetchRequest<Job> = Job.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", jobId as CVarArg)
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Failed to fetch job: \(error.localizedDescription)")
            return nil
        }
    }
    
 /*   func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let action = message["action"] as? String, action == "deleteJob", let jobIdString = message["jobId"] as? String {
            if let jobId = UUID(uuidString: jobIdString) {
                onDeleteJob?(jobId)

            }
        }
    } */




    
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
