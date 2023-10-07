//
//  EstTaxPicker.swift
//  ShiftTracker
//
//  Created by James Poole on 7/10/23.
//

import SwiftUI

struct EstTaxPicker: View {
    
    @Binding var taxPercentage: Double
    @Binding var isEditing: Bool
    
    var body: some View {
      
            VStack(alignment: .leading){
                Text("Estimated Tax")
                    .bold()
                    .padding(.vertical, 5)
                    .padding(.horizontal)
                    .glassModifier(cornerRadius: 20)
                    .padding(.leading, -3)
                
                Picker("Estimated tax:", selection: $taxPercentage) {
                    ForEach(Array(stride(from: 0, to: 50, by: 0.5)), id: \.self) { index in
                        Text(index / 100, format: .percent)
                    }
                }.pickerStyle(.wheel)
                    .frame(maxHeight: 100)
                    .disabled(!isEditing)
                    .tint(Color("SquaresColor"))
            }
            .padding(.horizontal, 5)
        
    }
}

#Preview {
    EstTaxPicker(taxPercentage: .constant(22), isEditing: .constant(false))
}
