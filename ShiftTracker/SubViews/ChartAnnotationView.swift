//
//  ChartAnnotationView.swift
//  ShiftTracker
//
//  Created by James Poole on 6/09/23.
//

import SwiftUI

struct ChartAnnotationView: View {
    
     var value: String
     var date: String
    
    var body: some View{
        HStack{
            VStack(alignment: .leading, spacing: 0){
            
            Text("TOTAL")
                .font(.footnote)
                .bold()
                .foregroundStyle(.gray)
                .roundedFontDesign()
                .padding(.top, 1)
            
            Text(value)
                .font(.title)
                .bold()
            
            Text(date)
                .font(.headline)
                .bold()
                .foregroundColor(.gray)
                .roundedFontDesign()
        
                
           
        }.padding(.leading, 8)
                .padding(.trailing)
        Spacer()
        }
            .padding(.vertical, 4)
           
    }
}
