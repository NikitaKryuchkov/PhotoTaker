//
//  UIExtensions.swift
//  TestTask
//
//  Created by Nikita Kryuchkov on 20.09.2021.
//

import UIKit

extension CGImage {
    var brightness: Double {
        let imageData = self.dataProvider?.data
        let ptr = CFDataGetBytePtr(imageData)
        var x = 0
        var result: Double = 0
        for _ in 0..<self.height {
            for _ in 0..<self.width {
                let red = ptr![0]
                let green = ptr![1]
                let blue = ptr![2]
                result += (0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue))
                x += 1
            }
        }
        let bright = result / Double(x)
        return bright
    }
}

extension UIImage {
    var brightness: Double {
        return (self.cgImage?.brightness)!
    }
}
