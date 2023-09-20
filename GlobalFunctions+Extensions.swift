//
//  GlobalFunctions.swift
//  ShiftTracker
//
//  Created by James Poole on 30/04/23.
//

import Foundation
import UIKit
import CoreLocation
import SwiftUI
import PopupView
import MapKit
import CoreData
import Haptics
import UserNotifications
import Charts


extension TimeInterval {
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)
        let hours = (time / 3600)
        let minutes = (time / 60) % 60
        let seconds = time % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
}

extension UIColor {
    var rgbComponents: (Float, Float, Float) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: nil)
        return (Float(r), Float(g), Float(b))
    }
}

func isBeforeEndOfToday(_ date: Date) -> Bool {
    let calendar = Calendar.current
    let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
    
    if let date = calendar.date(from: dateComponents), let today = calendar.date(from: todayComponents) {
        return date <= today
    }
    return false
    
}


extension CLPlacemark {
    var formattedAddress: String {
        let components = [subThoroughfare, thoroughfare, locality, administrativeArea, postalCode, country].compactMap { $0 }
        return components.joined(separator: ", ")
    }
}





extension NSNotification.Name {
    static let didEnterRegion = NSNotification.Name("didEnterRegionNotification")
    static let didExitRegion = NSNotification.Name("didExitRegionNotification")
}

func getDayOfWeek(date: Date) -> Int {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.weekday], from: date)
    return components.weekday ?? 0
}

func getDayShortName(day: Int) -> String {
    let formatter = DateFormatter()
    let symbols = formatter.shortWeekdaySymbols
    let symbol = symbols?[day % 7] ?? ""
    return String(symbol.prefix(1))
}

// for calculating a week ahead

func nextDate(dayOfWeek: Int, time: Date) -> Date? {
    let calendar = Calendar.current
    let now = Date()
    
    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
    var dateComponents = DateComponents()
    dateComponents.weekday = dayOfWeek
    dateComponents.hour = timeComponents.hour
    dateComponents.minute = timeComponents.minute
    
    let nextDate = calendar.nextDate(after: now, matching: dateComponents, matchingPolicy: .nextTime)
    
    return nextDate
}

public func wipeCoreData(in viewContext: NSManagedObjectContext) {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EntityName")
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
    
    let entityNames = ["Job", "OldShift", "Break", "JobLocation", "ScheduledShift", "Tip"]
    
    for entityName in entityNames {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(deleteRequest)
        } catch let error as NSError {
            // Handle the error
            print("Could not delete \(entityName). \(error), \(error.userInfo)")
        }
    }
}

// for rolling digit timer on TimerView

public func digitsFromTimeString(timeString: String) -> [Int] {
    return timeString.flatMap { char in
        if let digit = Int(String(char)) {
            return [abs(digit)]
        } else {
            return []
        }
    }
}

struct FadeMask: View {
    var body: some View {
        LinearGradient(gradient: Gradient(stops: [
            Gradient.Stop(color: Color.clear, location: 0),
            Gradient.Stop(color: Color.black, location: 0.1),
            Gradient.Stop(color: Color.black, location: 0.9),
            Gradient.Stop(color: Color.clear, location: 1),
        ]), startPoint: .top, endPoint: .bottom)
    }
}

struct RollingDigit: View {
    let digit: Int
    @State private var shouldAnimate = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ForEach((0...10), id: \.self) { index in
                    Text(index == 10 ? "0" : "\(index)")
                        .font(.system(size: geometry.size.height).monospacedDigit())
                        .bold()
                        .fontDesign(.rounded)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .offset(y: -CGFloat(digit) * geometry.size.height)
            .animation(shouldAnimate ? .easeOut(duration: 0.2) : nil)
            .onAppear {
                shouldAnimate = true
            }
            .onDisappear {
                shouldAnimate = false
            }
        }
    }
}




// test modifier to capture view height from Matthew's dev blog daringsnowball.net

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat?
    
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        guard let nextValue = nextValue() else { return }
        value = nextValue
    }
}

private struct ReadHeightModifier: ViewModifier {
    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: HeightPreferenceKey.self, value: geometry.size.height)
        }
    }
    
    func body(content: Content) -> some View {
        content.background(sizeView)
    }
}

extension View {
    func readHeight() -> some View {
        self
            .modifier(ReadHeightModifier())
    }
}

extension UIImage {
    func resized(to newSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            let hScale = newSize.height / size.height
            let vScale = newSize.width / size.width
            let scale = max(hScale, vScale) // scaleToFill
            let resizeSize = CGSize(width: size.width*scale, height: size.height*scale)
            var middle = CGPoint.zero
            if resizeSize.width > newSize.width {
                middle.x -= (resizeSize.width-newSize.width)/2.0
            }
            if resizeSize.height > newSize.height {
                middle.y -= (resizeSize.height-newSize.height)/2.0
            }
            
            draw(in: CGRect(origin: middle, size: resizeSize))
        }
    }
}

// because the focus state just straight up isnt working on JobView, lets use UIKit code - from hackingwithswift

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// used to create 3 default tags when the app launches

func createTags(in viewContext: NSManagedObjectContext) {
    let tagNames = ["Night", "Overtime", "Late"]
    let tagColors = [UIColor(.indigo), UIColor(.orange), UIColor(.pink)]
    
    for index in tagNames.indices {
        
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", tagNames[index])
        
        do {
            let existingTags = try viewContext.fetch(fetchRequest)
            
            if existingTags.isEmpty {
                let tag = Tag(context: viewContext)
                tag.name = tagNames[index]
                
                let (r, g, b) = tagColors[index].rgbComponents
                tag.colorRed = Double(r)
                tag.colorGreen = Double(g)
                tag.colorBlue = Double(b)
                tag.tagID = UUID()
                tag.editable = false
                
                try viewContext.save()
            }
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

func createDefaultTheme(in viewContext: NSManagedObjectContext, with themeManager: ThemeDataManager){
    
    let fetchRequest: NSFetchRequest<Theme> = Theme.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "name == %@", "Default")
    
    do {
        
        let existingDefault = try viewContext.fetch(fetchRequest)
        
        if existingDefault.isEmpty {
            
            let earningsColor = Color.green
            let customTextColor = Color.black
            let taxColor = Color.pink
            let timerColor = Color.orange
            let breaksColor = Color.indigo
            let customUIColor = Color.cyan
            let tipsColor = Color.teal
            
            let newTheme = Theme(context: viewContext)
            
            newTheme.name = "Default"
            
            let breaksComponents = UIColor(breaksColor).rgbComponents
            newTheme.breaksColorBlue = Double(breaksComponents.2)
            newTheme.breaksColorGreen = Double(breaksComponents.1)
            newTheme.breaksColorRed = Double(breaksComponents.0)
            
            let taxComponents = UIColor(taxColor).rgbComponents
            newTheme.taxColorRed = Double(taxComponents.0)
            newTheme.taxColorGreen = Double(taxComponents.1)
            newTheme.taxColorBlue = Double(taxComponents.2)
            
            let timerComponents = UIColor(timerColor).rgbComponents
            newTheme.timerColorRed = Double(timerComponents.0)
            newTheme.timerColorGreen = Double(timerComponents.1)
            newTheme.timerColorBlue = Double(timerComponents.2)
            
            let tipsComponents = UIColor(tipsColor).rgbComponents
            newTheme.tipsColorRed = Double(tipsComponents.0)
            newTheme.tipsColorGreen = Double(tipsComponents.1)
            newTheme.tipsColorBlue = Double(tipsComponents.2)
            
            let earningsComponents = UIColor(earningsColor).rgbComponents
            newTheme.earningsColorRed = Double(earningsComponents.0)
            newTheme.earningsColorGreen = Double(earningsComponents.1)
            newTheme.earningsColorBlue = Double(earningsComponents.2)
            
            let customUIComponents = UIColor(customUIColor).rgbComponents
            newTheme.customUIColorRed = Double(customUIComponents.0)
            newTheme.customUIColorGreen = Double(customUIComponents.1)
            newTheme.customUIColorBlue = Double(customUIComponents.2)
            
            
            newTheme.isSelected = true
            
            try viewContext.save()
            
            // for in future
            // themeManager.loadDefaultTheme()
            
            themeManager.selectTheme(theme: newTheme, context: viewContext)
            
        } else {
            
            // select the theme marked as selected in core data
            
            let fetchRequest: NSFetchRequest<Theme> = Theme.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isSelected == %@", NSNumber(value: true))

         
                
            if let theme = try viewContext.fetch(fetchRequest).first {
                
                
                themeManager.selectTheme(theme: theme, context: viewContext)
                
            }
                
            
            
            
        }
    } catch {
        let nsError = error as NSError
        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
}

struct CustomDisableListSelectionModifier: ViewModifier {
    
    var disabled: Bool
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *){
            content.selectionDisabled(disabled)
        } else {
            content // just allow selection on ios 16, not as clean but still will be undeletable
        }
    }
    
}

extension View {
    func customDisableListSelection(disabled: Bool) -> some View{
        self.modifier(CustomDisableListSelectionModifier(disabled: disabled))
    }
}


// applies hidden scroll background only if in dark mode

struct CustomScrollBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        Group {
            if colorScheme == .dark {
                content.scrollContentBackground(.hidden)
            } else {
                content
            }
        }
    }
}

extension View {
    func customScrollBackgroundModifier() -> some View {
        self.modifier(CustomScrollBackgroundModifier())
    }
}

struct CustomChartXSelection: ViewModifier {
    
    @Binding var selection: Date?
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            
            content.chartXSelection(value: $selection)
            
        } else {
            content
        }
    }
    
    
    
}

extension View {
    func customChartXSelectionModifier(selection: Binding<Date?>) -> some View {
        self.modifier(CustomChartXSelection(selection: selection))
    }
}

struct CustomChartOverlayModifier<V: View>: ViewModifier {
    
    // this overlay enabled is somewhat redudant now that we've discovered we can't use the gestures with tab view.
    
    @Binding var overlayEnabled: Bool
    let overlayContent: (ChartProxy) -> V
    
    func body(content: Content) -> some View {
        
        if #available(iOS 17.0, *) {
            // do nothing, use built-in modifier .chartXselection
            
            content
            
        } else {
            
            if overlayEnabled {
                content.chartOverlay(content: overlayContent)
            } else {
                content
            }
            
        }
    }
    
    
}

extension View {
    
    func conditionalChartOverlay<V: View>(overlayEnabled: Binding<Bool>, content: @escaping (ChartProxy) -> V) -> some View {
        
        self.modifier(CustomChartOverlayModifier(overlayEnabled: overlayEnabled, overlayContent: content))
        
    }
    
}

struct CustomAnimatedSymbolModifier<U:Hashable>: ViewModifier {
    
    @Binding var value: U
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *){
            content.symbolEffect(.bounce, value: value)
        } else {
            content
        }
    }
}

extension View {
    func customAnimatedSymbol<U: Hashable>(value: Binding<U>) -> some View {
        self.modifier(CustomAnimatedSymbolModifier(value: value))
    }
}


