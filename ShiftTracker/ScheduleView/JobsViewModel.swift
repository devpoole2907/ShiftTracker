//
//  JobsViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 30/04/23.
//

import Foundation
import Firebase
import FirebaseFirestore

class JobsViewModel: ObservableObject {
    
    @Published var firebaseJobs = [FirebaseJob]()
    
    func addData(name: String, title: String, hourlyPay: Double, address: String, clockInReminder: Bool, clockOutReminder: Bool, autoClockIn: Bool, autoClockOut: Bool, overtimeEnabled: Bool, overtimeAppliedAfter: Int16, overtimeRate: Double, icon: String, colorRed: Float, colorGreen: Float, colorBlue: Float, payPeriodLength: Int16, payPeriodStartDay: Int16) {
        let db = Firestore.firestore()
        let userID = Auth.auth().currentUser!.uid
        db.collection("jobs").document(userID).collection("userJobs").addDocument(data: [
            "name": name,
            "title": title,
            "hourlyPay": hourlyPay,
            "address": address,
            "clockInReminder": clockInReminder,
            "clockOutReminder": clockOutReminder,
            "autoClockIn": autoClockIn,
            "autoClockOut": autoClockOut,
            "overtimeEnabled": overtimeEnabled,
            "overtimeAppliedAfter": overtimeAppliedAfter,
            "overtimeRate": overtimeRate,
            "icon": icon,
            "colorRed": colorRed,
            "colorGreen": colorGreen,
            "colorBlue": colorBlue,
            "payPeriodLength": payPeriodLength,
            "payPeriodStartDay": payPeriodStartDay
        ]) { error in
            if error == nil {
                self.getData()
                
                
                
            } else {
                // we need to handle errors here, show a popup or something
            }
        }
    }
    
    func deleteData(jobToDelete: FirebaseJob){
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        db.collection("jobs").document(userID).collection("userJobs").document(jobToDelete.id).delete { error in
            if error == nil {
                
                
                DispatchQueue.main.async {
                    self.firebaseJobs.removeAll{ job in
                        return job.id == jobToDelete.id
                    }
                }
            }
        }
        
    }

    
    
    func getData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        
        db.collection("jobs").document(userID).collection("userJobs").getDocuments { snapshot, error in
            
            if error == nil {
                if let snapshot = snapshot {
                    
                    DispatchQueue.main.async {
                        self.firebaseJobs = snapshot.documents.map { doc in
                            
                            return FirebaseJob(id: doc.documentID, name: doc["name"] as? String ?? "",
                                               title: doc["title"] as? String ?? "",
                                               hourlyPay: doc["hourlyPay"] as? Double ?? 0,
                                               address: doc["address"] as? String ?? "",
                                               clockInReminder: doc["clockInReminder"] as? Bool ?? false,
                                               clockOutReminder: doc["clockOutReminder"] as? Bool ?? false,
                                               autoClockIn: doc["autoClockIn"] as? Bool ?? false,
                                               autoClockOut: doc["autoClockOut"] as? Bool ?? false,
                                               overtimeEnabled: doc["overtimeEnabled"] as? Bool ?? false,
                                               overtimeAppliedAfter: doc["overtimeAppliedAfter"] as? Int16 ?? 0,
                                               overtimeRate: doc["overtimeRate"] as? Double ?? 0,
                                               icon: doc["icon"] as? String ?? "briefcase.circle",
                                               colorRed: doc["colorRed"] as? Float ?? 0.0,
                                               colorGreen: doc["colorGreen"] as? Float ?? 0.0,
                                               colorBlue: doc["colorBlue"] as? Float ?? 0.0,
                                               payPeriodLength: doc["payPeriodLength"] as? Int16 ?? 0,
                                               payPeriodStartDay: doc["payPeriodStartDay"] as? Int16 ?? -1
                                               )
                        }
                    }
                    
                    
                }
            }
            else {
                
            }
            
        }
        
    }
    
    func updateData(jobToUpdate: FirebaseJob, name: String, title: String, hourlyPay: Double, address: String, clockInReminder: Bool, clockOutReminder: Bool, autoClockIn: Bool, autoClockOut: Bool, overtimeEnabled: Bool, overtimeAppliedAfter: Int16, overtimeRate: Double, icon: String, colorRed: Float, colorGreen: Float, colorBlue: Float, payPeriodLength: Int16, payPeriodStartDay: Int16) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let docRef = db.collection("jobs").document(userID).collection("userJobs").document(jobToUpdate.id)
        
        docRef.updateData([
            "name": name,
            "title": title,
            "hourlyPay": hourlyPay,
            "address": address,
            "clockInReminder": clockInReminder,
            "clockOutReminder": clockOutReminder,
            "autoClockIn": autoClockIn,
            "autoClockOut": autoClockOut,
            "overtimeEnabled": overtimeEnabled,
            "overtimeAppliedAfter": overtimeAppliedAfter,
            "overtimeRate": overtimeRate,
            "icon": icon,
            "colorRed": colorRed,
            "colorGreen": colorGreen,
            "colorBlue": colorBlue,
            "payPeriodLength": payPeriodLength,
            "payPeriodStartDay": payPeriodStartDay
        ]) { error in
            if error == nil {
                self.getData()
            } else {
                // Handle errors here, show a popup or something
            }
        }
    }

    
}
