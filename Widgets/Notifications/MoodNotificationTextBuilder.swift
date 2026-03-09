//
//  MoodNotificationTextBuilder.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//


import Foundation

struct MoodNotificationTextBuilder {
    func body(weather: WeatherSnapshot?) -> String {
        guard let weather else {
            return "How are you feeling right now? Take a moment to check in with yourself."
        }

        let condition = weather.conditionCode.lowercased()

        if condition.contains("rain") || condition.contains("drizzle") || condition.contains("storm") {
            return "It’s \(condition) right now. Weather can sometimes shift your energy—how is it affecting your mood today?"
        }

        let temp = weather.temperatureC

        if temp < 5 {
            return "It’s pretty cold out right now. Cold days can sometimes affect mood—want to log how you're feeling?"
        } else if temp > 28 {
            return "It’s pretty hot today. Heat can impact energy levels—how are you feeling?"
        } else {
            return "How are you feeling right now?"
        }

        

    }
}
