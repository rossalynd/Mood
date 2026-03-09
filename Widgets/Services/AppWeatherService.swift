//
//  AppWeatherService.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//

import Foundation
import CoreLocation
import WeatherKit

@available(iOS 26.0, *)
@MainActor
final class AppWeatherService {
    func fetchSnapshot(for location: CLLocation) async throws -> WeatherSnapshot {
        let weather = try await WeatherService.shared.weather(for: location)
        let current = weather.currentWeather

        return WeatherSnapshot(
            recordedAt: Date(),
            temperatureC: current.temperature.converted(to: .fahrenheit).value,
            conditionCode: current.symbolName
        )
    }
}
