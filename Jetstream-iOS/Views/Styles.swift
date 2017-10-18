//
//  Styles.swift
//  Jetstream
//
//  Created by Andrew Shepard on 6/19/17.
//  Copyright © 2017 Andrew Shepard. All rights reserved.
//

import UIKit

public let blueColor = UIColor.hexColor("#0998DC")

public func createBlankLabel() -> UILabel {
    let label = UILabel(frame: .zero)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .white
    label.numberOfLines = 0
    return label
}

public func createSmallCapsFont(withTextStyle textStyle: UIFontTextStyle) -> UIFont {
    var descriptor = UIFont.preferredFont(forTextStyle: textStyle).fontDescriptor
    let settings = [
        UIFontDescriptor.FeatureKey.featureIdentifier: kUpperCaseType,
        UIFontDescriptor.FeatureKey.typeIdentifier: kUpperCaseSmallCapsSelector
    ]
    let attributes = [UIFontDescriptor.AttributeName.featureSettings: [settings]]
    descriptor = descriptor.addingAttributes(attributes)
    
    return UIFont(descriptor: descriptor, size: descriptor.pointSize)
}
