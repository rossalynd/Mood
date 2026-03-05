//
//  WidgetsTargetBundle.swift
//  WidgetsTarget
//
//  Created by Rosie on 2/14/26.
//

import WidgetKit
import SwiftUI

@main
struct WidgetsTargetBundle: WidgetBundle {
    var body: some Widget {
        MoodWidget()
        HomeMoodWidget()
        WidgetsTargetControl()
        WidgetsTargetLiveActivity()
    }
}
