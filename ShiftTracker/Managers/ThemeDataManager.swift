//
//  ThemeDataManager.swift
//  ShiftTracker
//
//  Created by Louis Kolodzinski on 4/07/23.
//  Updated by James Poole on 20/09/23.
//

import SwiftUI
import CoreData

class ThemeDataManager: ObservableObject {
    @AppStorage("earningsColorRed") var earningsColorRed: Double = 1.0
    @AppStorage("earningsColorGreen") var earningsColorGreen: Double = 1.0
    @AppStorage("earningsColorBlue") var earningsColorBlue: Double = 1.0
    
    @AppStorage("customTextColorRed") var customTextColorRed: Double = 0.0
    @AppStorage("customTextColorGreen") var customTextColorGreen: Double = 0.0
    @AppStorage("customTextColorBlue") var customTextColorBlue: Double = 0.0
    
    @AppStorage("taxColorRed") var taxColorRed: Double = 1.0
    @AppStorage("taxColorGreen") var taxColorGreen: Double = 0.1764706
    @AppStorage("taxColorBlue") var taxColorBlue: Double = 0.33333334
    
    @AppStorage("timerColorRed") var timerColorRed: Double = 1.0
    @AppStorage("timerColorGreen") var timerColorGreen: Double = 0.58431375
    @AppStorage("timerColorBlue") var timerColorBlue: Double = 0.0
    
    @AppStorage("breaksColorRed") var breaksColorRed: Double = 0.34509805
    @AppStorage("breaksColorGreen") var breaksColorGreen: Double = 0.3372549
    @AppStorage("breaksColorBlue") var breaksColorBlue: Double = 0.8392157
    
    @AppStorage("customUIColorRed") var customUIColorRed: Double = 0.19607843
    @AppStorage("customUIColorGreen") var customUIColorGreen: Double = 0.6784314
    @AppStorage("customUIColorBlue") var customUIColorBlue: Double = 0.9019608
    
    @AppStorage("tipsColorRed") var tipsColorRed: Double = 0.19607843
    @AppStorage("tipsColorGreen") var tipsColorGreen: Double = 0.6784314
    @AppStorage("tipsColorBlue") var tipsColorBlue: Double = 0.9019608
    
    @Environment(\.colorScheme) var colorScheme
    
    
    
    @Published var selectedColorToChange: CustomColor = .customUIColorPicker
    @Published var selectedButton: Int? = nil
    @Published var showDetail = false
    
    @Published var currentThemeName: String = "Default"
    
    var originalEditingThemeName: String? // used for allowing the saving of a 'duplicate' theme if a theme is edited but the name is not changed
    
    // used for editing/creating new theme
    
    @Published var editingEarningsColor: Color = .green
    @Published var editingCustomTextColor: Color = .black
    @Published var editingTaxColor: Color = .pink
    @Published var editingTimerColor: Color = .orange
    @Published var editingBreaksColor: Color = .indigo
    @Published var editingCustomUIColor: Color = .cyan
    @Published var editingTipsColor: Color = .cyan
    
    @Published var editingThemeName: String = "Theme Name"
    
    let settingsGradient = LinearGradient(
        gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5), Color(.systemGray4)]),
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
    
    let contentViewGradient = LinearGradient(
        gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5), Color(.systemGray4)]),
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
    
    let jobOverviewGradient = LinearGradient(
        gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5), Color(.systemGray4)]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    let scheduleGradient =  LinearGradient(
        gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5), Color(.systemGray4)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    @AppStorage("pureDarkMode") var pureDark: Bool = false
    
    // just doing it this way instead of using the modifier, the modifier causes black screen issues when changing tabs.
    
    var settingsDynamicBackground: AnyView {
            if pureDark {
                return AnyView(Color.clear)
            } else {
                return AnyView(settingsGradient)
            }
        }
    
    var contentDynamicBackground: AnyView {
        if pureDark {
            return AnyView(Color.clear)
        } else {
            return AnyView(contentViewGradient)
        }
    }
    
    var scheduleDynamicBackground: AnyView {
        if pureDark {
            return AnyView(Color.clear)
        } else {
            return AnyView(scheduleGradient)
        }
    }
    
    var overviewDynamicBackground: AnyView {
        if pureDark {
            return AnyView(Color.clear)
        } else {
            return AnyView(jobOverviewGradient)
        }
    }
    
    
    @Published var earningsColor: Color {
        didSet {
            saveColor()
        }
    }
    
    @Published var customTextColor: Color {
        didSet {
            saveColor()
        }
    }
    
    @Published var taxColor: Color {
        didSet {
            saveColor()
        }
    }
    
    @Published var timerColor: Color {
        didSet {
            saveColor()
        }
    }
    
    @Published var breaksColor: Color {
        didSet {
            saveColor()
        }
    }
    
    @Published var customUIColor: Color {
        didSet {
            saveColor()
        }
    }
    
    @Published var tipsColor: Color {
        didSet {
            saveColor()
        }
    }

    
    
    
    init() {
        let earningsRed = UserDefaults.standard.double(forKey: "earningsColorRed")
        let earningsGreen = UserDefaults.standard.double(forKey: "earningsColorGreen")
        let earningsBlue = UserDefaults.standard.double(forKey: "earningsColorBlue")
        
        let textRed = UserDefaults.standard.double(forKey: "customTextColorRed")
        let textGreen = UserDefaults.standard.double(forKey: "customTextColorGreen")
        let textBlue = UserDefaults.standard.double(forKey: "customTextColorBlue")
        
        let taxRed = UserDefaults.standard.double(forKey: "taxColorRed")
        let taxGreen = UserDefaults.standard.double(forKey: "taxColorGreen")
        let taxBlue = UserDefaults.standard.double(forKey: "taxColorBlue")
        
        let timerRed = UserDefaults.standard.double(forKey: "timerColorRed")
        let timerGreen = UserDefaults.standard.double(forKey: "timerColorGreen")
        let timerBlue = UserDefaults.standard.double(forKey: "timerColorBlue")
        
        let breaksRed = UserDefaults.standard.double(forKey: "breaksColorRed")
        let breaksGreen = UserDefaults.standard.double(forKey: "breaksColorGreen")
        let breaksBlue = UserDefaults.standard.double(forKey: "breaksColorBlue")
        
        let customUIRed = UserDefaults.standard.double(forKey: "customUIColorRed")
        let customUIGreen = UserDefaults.standard.double(forKey: "customUIColorGreen")
        let customUIBlue = UserDefaults.standard.double(forKey: "customUIColorBlue")
        
        let tipsRed = UserDefaults.standard.double(forKey: "tipsColorRed")
        let tipsGreen = UserDefaults.standard.double(forKey: "tipsColorGreen")
        let tipsBlue = UserDefaults.standard.double(forKey: "tipsColorBlue")
        
        earningsColor = Color(red: earningsRed, green: earningsGreen, blue: earningsBlue)
        customTextColor = Color(red: textRed, green: textGreen, blue: textBlue)
        taxColor = Color(red: taxRed, green: taxGreen, blue: taxBlue)
        timerColor = Color(red: timerRed, green: timerGreen, blue: timerBlue)
        breaksColor = Color(red: breaksRed, green: breaksGreen, blue: breaksBlue)
        customUIColor = Color(red: customUIRed, green: customUIGreen, blue: customUIBlue)
        tipsColor = Color(red: tipsRed, green: tipsGreen, blue: tipsBlue)
        
        
        //resetColorsToDefaults()
    }
    
    func loadEditingColors(from theme: Theme) {
        editingEarningsColor = Color(red: theme.earningsColorRed, green: theme.earningsColorGreen, blue: theme.earningsColorBlue)
        editingTaxColor = Color(red: theme.taxColorRed, green: theme.taxColorGreen, blue: theme.taxColorBlue)
        editingTimerColor = Color(red: theme.timerColorRed, green: theme.timerColorGreen, blue: theme.timerColorBlue)
        editingBreaksColor = Color(red: theme.breaksColorRed, green: theme.breaksColorGreen, blue: theme.breaksColorBlue)
        editingCustomUIColor = Color(red: theme.customUIColorRed, green: theme.customUIColorGreen, blue: theme.customUIColorBlue)
        editingTipsColor = Color(red: theme.tipsColorRed, green: theme.tipsColorGreen, blue: theme.tipsColorBlue)
        editingThemeName = theme.name ?? "Unnamed Theme"
        
        originalEditingThemeName = editingThemeName
        
    }

    
    
    private func saveColor() {
        
    
        
        let earningsComponents = UIColor(earningsColor).rgbComponents
        earningsColorRed = Double(earningsComponents.0)
        earningsColorGreen = Double(earningsComponents.1)
        earningsColorBlue = Double(earningsComponents.2)
        
        let textComponents = UIColor(customTextColor).rgbComponents
        customTextColorRed = Double(textComponents.0)
        customTextColorGreen = Double(textComponents.1)
        customTextColorBlue = Double(textComponents.2)
        
        let taxComponents = UIColor(taxColor).rgbComponents
        taxColorRed = Double(taxComponents.0)
        taxColorGreen = Double(taxComponents.1)
        taxColorBlue = Double(taxComponents.2)
        
        let timerComponents = UIColor(timerColor).rgbComponents
        timerColorRed = Double(timerComponents.0)
        timerColorGreen = Double(timerComponents.1)
        timerColorBlue = Double(timerComponents.2)
        
        let breaksComponents = UIColor(breaksColor).rgbComponents
        breaksColorRed = Double(breaksComponents.0)
        breaksColorGreen = Double(breaksComponents.1)
        breaksColorBlue = Double(breaksComponents.2)
        
        let customUIComponents = UIColor(customUIColor).rgbComponents
        customUIColorRed = Double(customUIComponents.0)
        customUIColorGreen = Double(customUIComponents.1)
        customUIColorBlue = Double(customUIComponents.2)
        
        let tipsComponents = UIColor(tipsColor).rgbComponents
        tipsColorRed = Double(tipsComponents.0)
        tipsColorGreen = Double(tipsComponents.1)
        tipsColorBlue = Double(tipsComponents.2)
    }
    
    
    func resetColorsToDefaults() {
        
        
        
        earningsColor = Color.green
        customTextColor = Color.black
        taxColor = Color.pink
        timerColor = Color.orange
        breaksColor = Color.indigo
        customUIColor = Color.cyan
        tipsColor = Color.teal
        
        print("earningsColor default: \(UIColor(earningsColor).rgbComponents)")
        print("textColor default: \(UIColor(customTextColor).rgbComponents)")
        print("taxColor default: \(UIColor(taxColor).rgbComponents)")
        print("timerColor default: \(UIColor(timerColor).rgbComponents)")
        print("breaksColor default: \(UIColor(breaksColor).rgbComponents)")
        print("customUIColor default: \(UIColor(customUIColor).rgbComponents)")
        print("tipsColor default: \(UIColor(tipsColor).rgbComponents)")
        
        

        
    }
    
    func updateOrCreateTheme(_ theme: Theme? = nil, in viewContext: NSManagedObjectContext) {
        
        let newTheme = theme ?? Theme(context: viewContext)
        newTheme.name = editingThemeName
        
        let breaksComponents = UIColor(editingBreaksColor).rgbComponents
        newTheme.breaksColorBlue = Double(breaksComponents.2)
        newTheme.breaksColorGreen = Double(breaksComponents.1)
        newTheme.breaksColorRed = Double(breaksComponents.0)
        
        let taxComponents = UIColor(editingTaxColor).rgbComponents
        newTheme.taxColorRed = Double(taxComponents.0)
        newTheme.taxColorGreen = Double(taxComponents.1)
        newTheme.taxColorBlue = Double(taxComponents.2)
        
        let timerComponents = UIColor(editingTimerColor).rgbComponents
        newTheme.timerColorRed = Double(timerComponents.0)
        newTheme.timerColorGreen = Double(timerComponents.1)
        newTheme.timerColorBlue = Double(timerComponents.2)
        
        let tipsComponents = UIColor(editingTipsColor).rgbComponents
        newTheme.tipsColorRed = Double(tipsComponents.0)
        newTheme.tipsColorGreen = Double(tipsComponents.1)
        newTheme.tipsColorBlue = Double(tipsComponents.2)
        
        let earningsComponents = UIColor(editingEarningsColor).rgbComponents
        newTheme.earningsColorRed = Double(earningsComponents.0)
        newTheme.earningsColorGreen = Double(earningsComponents.1)
        newTheme.earningsColorBlue = Double(earningsComponents.2)
        
        let customUIComponents = UIColor(editingCustomUIColor).rgbComponents
        newTheme.customUIColorRed = Double(customUIComponents.0)
        newTheme.customUIColorGreen = Double(customUIComponents.1)
        newTheme.customUIColorBlue = Double(customUIComponents.2)
        
        if theme == nil {
            newTheme.isSelected = false
        }
        
       
        
        do {
            try viewContext.save()
            
            if newTheme.isSelected == true {
                selectTheme(theme: newTheme, context: viewContext)
            } else {
                CustomConfirmationAlert(action: {
                    
                    self.selectTheme(theme: newTheme, context: viewContext)
                    
                }, title: "Apply this theme?").showAndStack()
            }
            
        } catch {
            print("Error saving theme: \(error)")
        }
    }
    
    // used to select a theme/load it
    
    func selectTheme(theme: Theme, context: NSManagedObjectContext) {
        
        
        earningsColor = Color(red: theme.earningsColorRed, green: theme.earningsColorGreen, blue: theme.earningsColorBlue)

        taxColor = Color(red: theme.taxColorRed, green: theme.taxColorGreen, blue: theme.taxColorBlue)
        timerColor = Color(red: theme.timerColorRed, green: theme.timerColorGreen, blue: theme.timerColorBlue)
        breaksColor = Color(red: theme.breaksColorRed, green: theme.breaksColorGreen, blue: theme.breaksColorBlue)
        customUIColor = Color(red: theme.customUIColorRed, green: theme.customUIColorGreen, blue: theme.customUIColorBlue)
        tipsColor = Color(red: theme.tipsColorRed, green: theme.tipsColorGreen, blue: theme.tipsColorBlue)
   
        
        
        let fetchRequest: NSFetchRequest<Theme> = Theme.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isSelected == %@", NSNumber(value: true))
        
        do {
            let previouslySelectedThemes = try context.fetch(fetchRequest)
            for oldTheme in previouslySelectedThemes {
                oldTheme.isSelected = false
            }
            
            theme.isSelected = true
            try context.save()
        } catch let error as NSError {
            print("Failed to fetch or save: \(error), \(error.userInfo)")
        }
        
        self.currentThemeName = theme.name ?? "Error"
    
    }
    
    
}


