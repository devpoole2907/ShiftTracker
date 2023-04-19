//
//  TaxPickerView.swift
//  ShiftTracker
//
//  Created by James Poole on 7/04/23.
//

import SwiftUI

struct TaxPickerView: View {
    @Binding var taxPercentage: Double

    var body: some View {
        
        NavigationStack{
            
            VStack(alignment: .center){
                Picker("Estimated tax:", selection: $taxPercentage) {
                    ForEach(Array(stride(from: 0, to: 50, by: 0.5)), id: \.self) { index in
                        Text(index / 100, format: .percent)
                    }
                    
                }.pickerStyle(.wheel)
                
                    .accentColor(.white.opacity(0.7))
                
            }.navigationBarTitle("Select Estimated Tax", displayMode: .inline)
        }
        
        
        
        
        
     /*   NavigationStack{
            
                List {
                    Section{
                        VStack{
                            Spacer(minLength: UIScreen.main.bounds.height / 4)
                            Picker("Estimated tax:", selection: $taxPercentage) {
                                ForEach(Array(stride(from: 0, to: 50, by: 0.5)), id: \.self) { index in
                                    Text(index / 100, format: .percent)
                                }
                                
                            }.pickerStyle(.wheel)
                        Spacer()
                        }
                    }.listRowBackground(Color.clear)
                }
                 
               // .frame(minWidth: UIScreen.main.bounds.width / 3)
               // .bold()

               // .cornerRadius(12)
                .accentColor(.white.opacity(0.7))
                
                .navigationBarTitle("Select Tax", displayMode: .inline)
        } */
        
    }
}

struct TaxPickerView_Previews: PreviewProvider {
    static var previews: some View {
        TaxPickerView(taxPercentage: .constant(10.5))
    }
}
