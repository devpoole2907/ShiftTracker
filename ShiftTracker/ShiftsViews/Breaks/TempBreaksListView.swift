//
//  TempBreaksListView.swift
//  ShiftTracker
//
//  Created by James Poole on 12/08/23.
//

import SwiftUI

struct TempBreaksListView: View {
    @Binding var breaks: [TempBreak]
    
    let breakManager = BreaksManager()
    
    @State private var newBreakStartDate = Date()
    @State private var newBreakEndDate = Date()
    @State private var isUnpaid = false
    
    private func delete(at offsets: IndexSet) {
        breaks.remove(atOffsets: offsets)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy   h:mm a"
        return formatter.string(from: date)
    }
    
    
    var body: some View {
        ForEach(breaks, id: \.self) { breakItem in
            Section{
                VStack(alignment: .leading){
                    VStack(alignment: .leading, spacing: 8){
                        if breakItem.isUnpaid{
                            Text("Unpaid")
                                .font(.subheadline)
                                .foregroundColor(.indigo)
                                .bold()
                        }
                        else {
                            Text("Paid")
                                .font(.subheadline)
                                .foregroundColor(.indigo)
                                .bold()
                        }
                        Text("\(breakManager.breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate))")
                            .listRowSeparator(.hidden)
                            .font(.subheadline)
                            .bold()
                    }
                    Divider()
                    HStack{
                        Text("Start:")
                            .bold()
                        //.padding(.horizontal, 15)
                            .frame(width: 50, alignment: .leading)
                            .padding(.vertical, 5)
                        
                        Text(formatDate(breakItem.startDate))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    HStack{
                        Text("End:")
                            .bold()
                            .frame(width: 50, alignment: .leading)
                        //.padding(.horizontal, 15)
                            .padding(.vertical, 5)
                        Text(formatDate(breakItem.endDate ?? Date()))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }.padding()
                    .background(Color("SquaresColor"),in:
                                    RoundedRectangle(cornerRadius: 12, style: .continuous))
                
            }.listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }.onDelete(perform: delete)
    }
}
