//
//  Tag.swift
//  ShiftTracker
//
//  Created by James Poole on 4/04/23.
//


import Foundation

public class Tag: NSObject, Codable, NSCoding {
    var name: String
    var colorName: String

    init(name: String, colorName: String) {
        self.name = name
        self.colorName = colorName
    }

    public func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(colorName, forKey: "colorName")
    }

    required public init?(coder: NSCoder) {
        name = coder.decodeObject(forKey: "name") as? String ?? ""
        colorName = coder.decodeObject(forKey: "colorName") as? String ?? ""
    }
}
