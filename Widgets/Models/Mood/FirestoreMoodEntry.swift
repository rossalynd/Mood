//
//  FirestoreMoodEntry.swift
//  Widgets
//
//  Created by Rosie on 3/8/26.
//


import Foundation
import FirebaseFirestore

struct FirestoreMoodEntry: Codable, Identifiable {
    @DocumentID var id: String?

    var moodValue: Int
    var moodKey: String
    var emoji: String
    var labels: [String]
    var contextTags: [String]
    var note: String?
    var journalAnswer: String?
    var visibility: String
    var media: [MoodMediaItem]
    var weather: WeatherSnapshot?
    var createdAt: Date
    var updatedAt: Date
    var deviceId: String
}
