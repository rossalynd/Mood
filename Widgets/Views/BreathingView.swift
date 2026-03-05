//
//  BreathingView.swift
//  Widgets
//
//  Created by Rosie on 3/5/26.
//


//
//  InsightsView.swift
//  Widgets
//
//  Created by Rosie on 3/3/26.
//

import Foundation
import SwiftUI
import AVFoundation

@available(iOS 26.0, *)
struct BreathingView: View {
    @Binding var path: NavigationPath
    @Environment(\.dismiss) private var dismiss

    @State private var player: AVAudioPlayer?
    @State private var lotusAnimate = false
    @State private var beginBreathingExercise = false
    @State private var didFinish = false

    // Total exercise length (leave time before 105s song ends)
    private let exerciseSeconds: Double = 95

    func playSong() {
        guard let url = Bundle.main.url(forResource: "breathing", withExtension: "mp3") else {
            print("❌ Could not find breathing.mp3 in bundle")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [])
            try session.setActive(true)

            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 0
            player?.numberOfLoops = 0
            player?.prepareToPlay()
            player?.play()
            player?.setVolume(1.0, fadeDuration: 2)
        } catch {
            print("❌ Audio failed to play:", error.localizedDescription)
        }
    }

    private func stopSong(fadeOut: Double = 1.5) {
        guard let player else { return }
        player.setVolume(0, fadeDuration: fadeOut)

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(fadeOut))
            player.stop()
            self.player = nil
        }
    }

    private func close() {
        stopSong(fadeOut: 0.3)
        path.removeLast()
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LiquidBackdrop().ignoresSafeArea()

           

            VStack() {
Spacer()
                LotusFloatingView(isAnimating: lotusAnimate)
                    .onAppear { lotusAnimate = true }
                    
Spacer()
                if !beginBreathingExercise {
                    Button {
                        didFinish = false
                        beginBreathingExercise = true
                        playSong()
                    } label: {
                        Text("Start")
                            .font(.title)
                            .padding()
                    }
                    .padding()
                   
                    .buttonStyle(.glass)
                    .padding(.top, 6)

                } else {
                    GuidedBreathingView(
                        totalSeconds: exerciseSeconds,
                        onFinished: {
                            didFinish = true
                            stopSong(fadeOut: 2.0)
                        }
                    )
                    Spacer()
                }

                
            }
            .padding(20)
        }
        
        .onDisappear {
            // safety: if user navigates away, stop audio
            stopSong(fadeOut: 0.2)
        }
    }
}

@available(iOS 26.0, *)
private struct LotusFloatingView: View {
    let isAnimating: Bool

    var body: some View {
        Image("lotus")
            .resizable()
            .scaledToFit()
            .padding(30)
            .offset(y: isAnimating ? 0 : 32)
            .opacity(isAnimating ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
            .transaction { t in t.animation = nil }
    }
}

import SwiftUI

struct GuidedBreathingView: View {

    let totalSeconds: Double
    let onFinished: () -> Void

    // MARK: - Script (edit freely)
    private let script: [(text: String, seconds: Double)] = [
        ("Welcome.", 2.0),
        ("Find a comfortable position.", 3.0),
        ("Let your shoulders drop.", 3.5),
        ("Unclench your jaw.", 3.0),
        ("Soften your gaze or close your eyes.", 3.5),
        ("Take one easy breath in…", 4.3),
        ("And let it go.", 3.5),
        ("We’ll begin together in a moment.", 5)
    ]

    // MARK: - Timings (tweak)
    private let fadeIn: Double = 0.5
    private let fadeOut: Double = 0.5
    private let pauseInvisibleBetweenLines: Double = 1.5

    private let inhaleSeconds: Double = 4
    private let holdSeconds: Double = 4
    private let exhaleSeconds: Double = 6

    enum Mode { case intro, breathing, finished }
    enum Phase: String { case inhale = "Breathe In", hold = "Hold", exhale = "Breathe Out" }

    @State private var mode: Mode = .intro

    // Intro state
    @State private var introIndex: Int = 0
    @State private var introVisible: Bool = false

    // Breathing state
    @State private var phase: Phase = .inhale
    @State private var breatheExpand: Bool = false

    // Task handle so we can stop cleanly
    @State private var sessionTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            switch mode {
            case .intro:
                introView
            case .breathing:
                breathingView
            case .finished:
                finishedView
            }
        }
        .onAppear { start() }
        .onDisappear {
            sessionTask?.cancel()
            sessionTask = nil
        }
    }

    private var introView: some View {
        Text(script[introIndex].text)
            .font(.system(size: 24, weight: .semibold))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 28)
            .opacity(introVisible ? 1 : 0)
            .animation(.smooth(duration: introVisible ? fadeIn : fadeOut), value: introVisible)
            
    }

    private var breathingView: some View {
        Text(phase.rawValue)
            .font(.system(size: 44, weight: .semibold, design: .rounded))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 28)
            .scaleEffect(breatheExpand ? 1.18 : 0.92)
            .opacity(breatheExpand ? 1.0 : 0.55)
            .animation(.easeInOut(duration: currentPhaseDuration), value: breatheExpand)
            .animation(nil, value: introIndex)
            
    }

    private var finishedView: some View {
        VStack(spacing: 14) {
            Text("Nice work.")
                .font(.system(size: 40, weight: .semibold, design: .rounded))
            Text("Take one more easy breath and return when you’re ready.")
                .font(.system(size: 20, weight: .regular, design: .rounded))
                .multilineTextAlignment(.center)
                .opacity(0.85)
                .padding(.horizontal, 28)
        }
        .transition(.opacity)
    }

    private var currentPhaseDuration: Double {
        switch phase {
        case .inhale: return inhaleSeconds
        case .hold:   return holdSeconds
        case .exhale: return exhaleSeconds
        }
    }

    // MARK: - Orchestration
    private func start() {
        // Cancel any previous run (prevents double-start)
        sessionTask?.cancel()

        sessionTask = Task { @MainActor in
            // Start a timer in parallel that ends the session
            let endTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(totalSeconds))
                finish()
            }

            await runIntro()
            if Task.isCancelled { endTask.cancel(); return }

            mode = .breathing
            await runBreathingLoopUntilFinished()

            endTask.cancel()
        }
    }

    private func finish() {
        guard mode != .finished else { return }
        sessionTask?.cancel()
        sessionTask = nil

        withAnimation(.easeInOut(duration: 0.6)) {
            mode = .finished
        }
        onFinished()
    }

    private func runBreathingLoopUntilFinished() async {
        // Loop until cancelled (we cancel when totalSeconds hits)
        while !Task.isCancelled {
            await setPhase(.inhale, expand: true,  seconds: inhaleSeconds)
            if Task.isCancelled { break }
            await setPhase(.hold,   expand: true,  seconds: holdSeconds)
            if Task.isCancelled { break }
            await setPhase(.exhale, expand: false, seconds: exhaleSeconds)
        }
    }

    private func runIntro() async {
        mode = .intro
        introVisible = false
        try? await Task.sleep(for: .seconds(0.05))

        for i in script.indices {
            if Task.isCancelled { return }

            introVisible = false
            try? await Task.sleep(for: .seconds(0.05))
            
            var tx = Transaction()
            tx.disablesAnimations = true
            withTransaction(tx) { introIndex = i }

            try? await Task.sleep(for: .seconds(pauseInvisibleBetweenLines))

            introVisible = true
            try? await Task.sleep(for: .seconds(fadeIn))

            let hold = max(0, script[i].seconds - fadeIn - fadeOut)
            if hold > 0 {
                try? await Task.sleep(for: .seconds(hold))
            }

            introVisible = false
            try? await Task.sleep(for: .seconds(fadeOut))
        }
    }

    private func setPhase(_ newPhase: Phase, expand: Bool, seconds: Double) async {
        if Task.isCancelled { return }
        var tx = Transaction()
        tx.disablesAnimations = true
        withTransaction(tx) { phase = newPhase }
        breatheExpand = expand
        try? await Task.sleep(for: .seconds(seconds))
    }
}

@available(iOS 26.0, *)
#Preview {
    @Previewable @State var path = NavigationPath()
   
    BreathingView(path: $path)
        .environmentObject(DeepLinkRouter())
      
}

