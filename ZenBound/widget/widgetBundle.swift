//
//  widgetBundle.swift
//  widget
//
//  Created by Jack on 21/1/2026.
//

import WidgetKit
import SwiftUI

@main
struct widgetBundle: WidgetBundle {
    var body: some Widget {
        widget()
        if #available(iOS 18.0, *) {
            widgetControl()
        }
        widgetLiveActivity()
    }
}
