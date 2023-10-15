//
//  AppIconManager.swift
//  ShiftTracker
//
//  Created by Louis Kolodzinski on 20/07/23.
//
import UIKit



final class AppIconManager: ObservableObject {
    
    enum AppIcon: String, CaseIterable, Identifiable {
        case primary = "AppIcon"
        case hourglassDark = "HourglassDarkIcon"
        case darkModeFlat = "DarkModeIcon"
        case lightModeFlat = "LightModeIcon"
        case calendarTick = "CalendarTickIcon"
        case alphaIcon = "AlphaIcon"
        case alphaIcon2 = "AlphaIcon2"
        case betaIcon = "BetaIcon"
        
        var id: String { rawValue }
        var iconName: String? {
            switch self {
            case .primary:
                return nil
            default:
                return rawValue
            }
        }
        
        var description: String {
            switch self{
            case .primary:
                return "Default"
            case .hourglassDark:
                return "Hourglass Dark"
            case .darkModeFlat:
                return "Dark Flat"
            case .lightModeFlat:
                return "Light Flat"
            case .calendarTick:
                return "Minimalistic Calendar"
            case .alphaIcon:
                return "Alpha"
            case .alphaIcon2:
                return "Alpha 2"
            case .betaIcon:
                return "Beta"
            }
        }
        
        var preview: String {
            return rawValue + "-Preview"
        }

    }
    
    @Published private(set) var selectedAppIcon: AppIcon
    
    init() {
        if let iconName = UIApplication.shared.alternateIconName, let appIcon = AppIcon(rawValue: iconName) {
            selectedAppIcon = appIcon
        } else {
            selectedAppIcon = .primary
        }
    }
    
    func changeIcon(to icon: AppIcon) {
        let previousAppIcon = selectedAppIcon
        selectedAppIcon = icon
        
        Task { @MainActor in
            guard UIApplication.shared.alternateIconName != icon.iconName else {
                return
            }
            
            do {
                try await UIApplication.shared.setAlternateIconName(icon.iconName)
            } catch {

                print("Updating icon to \(String(describing: icon.iconName)) failed.")
            
                selectedAppIcon = previousAppIcon
            }
        }
    }
}
