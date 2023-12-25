//
//  CIFilter+functions.swift
//  InstafilterHWS
//
//  Created by Sharan Thakur on 25/12/23.
//

import CoreImage

extension CIFilter {
    func setValueIfAvailable(_ value: Any?, forKey key: String) {
        if inputKeys.contains(key) {
            setValue(value, forKey: key)
        }
    }
    
    var shortName: String {
        name.replacing("CI", with: "")
    }
}
