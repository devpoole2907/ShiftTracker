//
//  ThemesList.swift
//  ShiftTracker
//
//  Created by James Poole on 20/09/23.
//

import SwiftUI
import CoreData

struct ThemesList: View {
    
    @EnvironmentObject var themeManager: ThemeDataManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.editMode) private var editMode
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
           entity: Theme.entity(),
           sortDescriptors: [NSSortDescriptor(keyPath: \Theme.name, ascending: true)]
       ) private var themes: FetchedResults<Theme>
    
    @Binding var showingProView: Bool
    
    @State private var themeSelection: Set<NSManagedObjectID> = []
    
    @State private var themeToEdit: Theme?
    
    @State private var activeSheet: ActiveSheet?
    
    @AppStorage("isFirstAppear") var isFirstAppear = true
    
    enum ActiveSheet: Identifiable {
        
        public var id: Int {
            hashValue
        }
        
    case infoSheet
        case addSheet
    }
    
    var body: some View {
        
        ZStack(alignment: .bottomTrailing) {
            List(selection: $themeSelection) {
                
                ForEach(themes, id: \.self) { theme in
                    
                    ThemeRow(theme: theme)
                        .contentShape(Rectangle())
                        .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
                    
                     //   .customDisableListSelection(disabled: theme.name == "Default")
                    
                        .onTapGesture {
                            if !(editMode?.wrappedValue.isEditing ?? false) {
                                if !theme.isSelected {
                                    CustomConfirmationAlert(action: {
                                        withAnimation {
                                            themeManager.selectTheme(theme: theme, context: viewContext)
                                        }
                                        
                                    }, cancelAction: nil, title: "Apply this theme?").showAndStack()
                                    
                                }
                            }
                        }
                    
                        .swipeActions {
                            if theme.name != "Default" {
                                Button(role: .destructive) { 
                                    DispatchQueue.main.async {
                                        deleteTheme(theme)
                                        
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                }
                                
                                Button(role: .none) {  
                                    themeToEdit = theme
                                    activeSheet = .addSheet
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                
                            }
                        }
                    
                }
                
                .sheet(item: $activeSheet, onDismiss: { themeToEdit = nil }) { sheet in
                    switch sheet {
                    case .infoSheet: // old
                        ThemesGuideView()
                            .presentationDetents([.fraction(0.8)])
                            .customSheetBackground()
                            .customSheetRadius()
                    case .addSheet:
                        
                        ThemeView(theme: themeToEdit, errorAction: {
                            activeSheet = .addSheet
                        })
                            .presentationDetents([.fraction(0.72)])
                            .customSheetRadius()
                            .customSheetBackground()
                    }
                }
                
                
                
            }.scrollContentBackground(.hidden)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
      //  .background(Color(.systemGroupedBackground).ignoresSafeArea())
            
                .background(Color.clear)
            
            VStack{
            
            HStack(spacing: 10){
                
                EditButton()
                
                Divider().frame(height: 10)
                
                if editMode?.wrappedValue.isEditing == true {
                    
                    Button(action: {
                        CustomConfirmationAlert(action: deleteThemes, cancelAction: nil, title: "Are you sure?").showAndStack()
                    }) {
                        Image(systemName: "trash").customAnimatedSymbol(value: $themeSelection)
                            .bold()
                    }.disabled(themeSelection.isEmpty)
                        .tint(.red)
                    
                } else {
                    Button(action: {
                        
                        activeSheet = .addSheet
                        
                        
                    }){
                        Image(systemName: "plus").customAnimatedSymbol(value: $themeSelection)
                            .bold()
                    }
                }
                
                
                
                
            }.padding()
                    .glassModifier(cornerRadius: 20)
  
            }.padding()
            
            
        } .navigationTitle("Themes")
    
            .background(Color.clear)
        
            .onAppear {
                
                if !purchaseManager.hasUnlockedPro {
              
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                        dismiss()
                        showingProView.toggle()
                    }
                    
                }
                
            }
        
    }
    
    
    private func deleteTheme(_ theme: Theme) {
            withAnimation {
                if theme.name != "Default" {
                    
                    if theme.isSelected {
                        if let defaultTheme = themes.first(where: { $0.name == "Default" }){
                            themeManager.selectTheme(theme: defaultTheme, context: viewContext)
                        }
                    }
                    
                    viewContext.delete(theme)
                    
                }
                do {
                    try viewContext.save()
                } catch {
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }
        }
    
    private func deleteThemes() {
        withAnimation {
            themeSelection.forEach { objectID in
                    if let themeToDelete = viewContext.object(with: objectID) as? Theme {
                        if themeToDelete.name != "Default" {
                            viewContext.delete(themeToDelete)
                        }
                    }
                }
            
            do {
                try viewContext.save()
                themeSelection.removeAll()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
}

#Preview {
    ThemesList(showingProView: .constant(false))
}

struct ThemeRow: View {
    
    @ObservedObject var theme: Theme
    
    var colors: [Color] = []
    
    init(theme: Theme) {
        self.theme = theme
        
        colors.append(Color(red: theme.taxColorRed, green: theme.taxColorGreen, blue: theme.taxColorBlue))
        colors.append(Color(red: theme.tipsColorRed, green: theme.tipsColorGreen, blue: theme.tipsColorBlue))
        colors.append(Color(red: theme.timerColorRed, green: theme.timerColorGreen, blue: theme.timerColorBlue))
        colors.append(Color(red: theme.breaksColorRed, green: theme.breaksColorGreen, blue: theme.breaksColorBlue))
        
    }
    
    var body: some View {

        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(theme.name ?? "Theme")
                    .font(.largeTitle)
                    .bold()
                    .roundedFontDesign()
                    .allowsTightening(true)
                
                Divider().frame(maxWidth: 150)
                
                HStack {
                    
                    ForEach(colors, id: \.self) { color in
                        
                        Circle().foregroundStyle(color)
                            .frame(width: 25, height: 25)
                    }
                    
                }.padding(5)
                
            }//.glassModifier(cornerRadius: 20)
            
            Spacer()
            
      
                
            if theme.isSelected {
                
                   CustomCheckbox()
                
                
                 } else {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white, lineWidth: 3)
                
                    .frame(maxWidth: 25, maxHeight: 25)
                
                    }
                
            
            
        }
        
    }
    
    
}
