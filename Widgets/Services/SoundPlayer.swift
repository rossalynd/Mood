//
//  SoundPlayer.swift
//  Widgets
//
//  Created by Rosie on 3/5/26.
//

import AVFoundation

@MainActor
class SoundPlayer {
    static var player: AVAudioPlayer?

    static func play(_ name: String, type: String = "wav") {
        if let url = Bundle.main.url(forResource: name, withExtension: type) {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.play()
            } catch {
                print("Failed to play sound")
            }
        }
    }
}
