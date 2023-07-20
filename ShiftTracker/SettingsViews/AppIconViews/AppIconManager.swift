//
//  AppIconManager.swift
//  ShiftTracker
//
//  Created by Louis Kolodzinski on 20/07/23.
//
import UIKit



final class ChangeAppIconViewModel: ObservableObject {
    
    enum AppIcon: String, CaseIterable, Identifiable {
        case primary = "AppIcon"
        case lightMode = "AppIcon-Light"
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
            case .lightMode:
                return "Light Mode"
            case .alphaIcon:
                return "Alpha Icon"
            case .alphaIcon2:
                return "Alpha Icon 2"
            case .betaIcon:
                return "Beta Icon"
            }
        }
        
        var preview: UIImage {
            UIImage(named: rawValue + "-Preview") ?? UIImage()
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
    
    func updateAppIcon(to icon: AppIcon) {
        let previousAppIcon = selectedAppIcon
        selectedAppIcon = icon
        
        Task { @MainActor in
            guard UIApplication.shared.alternateIconName != icon.iconName else {
                /// No need to update since we're already using this icon.
                return
            }
            
            do {
                try await UIApplication.shared.setAlternateIconName(icon.iconName)
            } catch {
                /// We're only logging the error here and not actively handling the app icon failure
                /// since it's very unlikely to fail.
                print("Updating icon to \(String(describing: icon.iconName)) failed.")
                
                /// Restore previous app icon
                selectedAppIcon = previousAppIcon
            }
        }
    }
}
