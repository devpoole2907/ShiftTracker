//
//  ProFeature.swift
//  ShiftTracker
//
//  Created by James Poole on 19/11/23.
//

import Foundation

struct ProFeature: Hashable {
    let image: String
    let text: String
}

let proFeatures = [
    ProFeature(image: "clipboard", text: "Multiple Jobs"), ProFeature(image: "play.rectangle", text: "Live Activities"), ProFeature(image: "location", text: "Location based clock in & clock out"), ProFeature(image: "paintpalette", text: "Custom Themes"), ProFeature(image: "square.and.arrow.up", text: "Data Exporting"), ProFeature(image: "photo.on.rectangle.angled", text: "Custom App Icons")
]
