//
//  MoodData.swift
//  Widgets
//
//  Created by Rosie on 3/4/26.
//

// MARK: - Sort Mode
import Foundation
import SwiftUI
import HealthKit

@available(iOS 26.0, *)
enum MoodSort: Hashable {
    case byLevel
    case alphabetical
}

// MARK: - Mood Item + Cell (ZStack + circle + label chip)

@available(iOS 26.0, *)
struct MoodItem: Identifiable, Hashable {
    let label: HKStateOfMind.Label
    var id: Int { label.rawValue }

    var displayName: String { label.displayName }
    var emoji: Image { label.emoji }
    var level: MoodLevel { label.level }
}

@available(iOS 26.0, *)
struct MoodCell: View {
    let mood: MoodItem
    let isSelected: Bool

    @State private var bump = false

    var body: some View {
        VStack {
            
            ZStack {
                Circle()
                    .fill(isSelected ? mood.level.color.opacity(0.45) : mood.level.color)
               
                mood.emoji
                    .resizable()
                    .frame(maxWidth: 60, maxHeight: 60)
                    
                    
                
            }
            
            Text(mood.displayName)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .scaleEffect(bump ? 1.08 : 1.0)
        
        .onChange(of: isSelected) { _, newValue in
            guard newValue else { return } // only when it becomes selected

            // kick the bump on
            bump = true

            // animate back off
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                bump = false
            }
        }
        // separate animations feels nicer: snappy up, springy back
        .animation(.easeOut(duration: 0.12), value: bump) // up + stroke widen
        .animation(.spring(response: 0.28, dampingFraction: 0.65), value: isSelected)
       
    }
}



// MARK: - Labels list (Apple-defined)

@available(iOS 26.0, *)
struct AppleMoodLabels {
    static let all: [HKStateOfMind.Label] = [
        .amazed, .amused, .angry, .annoyed, .anxious, .ashamed, .brave, .calm, .confident,
        .content, .disappointed, .discouraged, .disgusted, .drained, .embarrassed, .excited,
        .frustrated, .grateful, .guilty, .happy, .hopeful, .hopeless, .indifferent, .irritated,
        .jealous, .joyful, .lonely, .overwhelmed, .passionate, .peaceful, .proud, .relieved,
        .sad, .satisfied, .scared, .stressed, .surprised, .worried
    ]
}

// MARK: - 5-level model + mappings (name / emoji / level / color / valence)

@available(iOS 26.0, *)
enum MoodLevel: Int, Hashable, CaseIterable {
    case veryNegative = 1
    case negative = 2
    case neutral = 3
    case positive = 4
    case veryPositive = 5

    var sortRank: Int { rawValue } // 1..5

    var color: Color {
        switch self {
        case .veryNegative: return .indigo
        case .negative:     return .orange
        case .neutral:      return .yellow
        case .positive:     return .pink
        case .veryPositive: return .purple
        }
    }

    var sectionTitle: String {
        switch self {
        case .veryPositive: return "Very Positive"
        case .positive:     return "Positive"
        case .neutral:      return "Neutral"
        case .negative:     return "Negative"
        case .veryNegative: return "Very Negative"
        }
    }

    static var sortedDescending: [MoodLevel] {
        [.veryPositive, .positive, .neutral, .negative, .veryNegative]
    }
}

@available(iOS 26.0, *)
extension HKStateOfMind.Label {

    var displayName: String {
        switch self {
        case .amazed: return "Amazed"
        case .amused: return "Amused"
        case .angry: return "Angry"
        case .annoyed: return "Annoyed"
        case .anxious: return "Anxious"
        case .ashamed: return "Ashamed"
        case .brave: return "Brave"
        case .calm: return "Calm"
        case .confident: return "Confident"
        case .content: return "Content"
        case .disappointed: return "Disappointed"
        case .discouraged: return "Discouraged"
        case .disgusted: return "Disgusted"
        case .drained: return "Drained"
        case .embarrassed: return "Embarrassed"
        case .excited: return "Excited"
        case .frustrated: return "Frustrated"
        case .grateful: return "Grateful"
        case .guilty: return "Guilty"
        case .happy: return "Happy"
        case .hopeful: return "Hopeful"
        case .hopeless: return "Hopeless"
        case .indifferent: return "Indifferent"
        case .irritated: return "Irritated"
        case .jealous: return "Jealous"
        case .joyful: return "Joyful"
        case .lonely: return "Lonely"
        case .overwhelmed: return "Overwhelmed"
        case .passionate: return "Passionate"
        case .peaceful: return "Peaceful"
        case .proud: return "Proud"
        case .relieved: return "Relieved"
        case .sad: return "Sad"
        case .satisfied: return "Satisfied"
        case .scared: return "Scared"
        case .stressed: return "Stressed"
        case .surprised: return "Surprised"
        case .worried: return "Worried"
        @unknown default: return "Mood"
        }
    }

    var emoji: Image {
        switch self {
        case .amazed: return Image("Amazed")
        case .amused: return Image("Amused")
        case .angry: return Image("Angry")
        case .annoyed: return Image("Annoyed")
        case .anxious: return Image("Anxious")
        case .ashamed: return Image("Ashamed")
        case .brave: return Image("Brave")
        case .calm: return Image("Calm")
        case .confident: return Image("Confident")
        case .content: return Image("Content")
        case .disappointed: return Image("Disappointed")
        case .discouraged: return Image("Discouraged")
        case .disgusted: return Image("Disgusted")
        case .drained: return Image("Drained")
        case .embarrassed: return Image("Embarrassed")
        case .excited: return Image("Excited")
        case .frustrated: return Image("Frustrated")
        case .grateful: return Image("Grateful")
        case .guilty: return Image("Guilty")
        case .happy: return Image("Happy")
        case .hopeful: return Image("Hopeful")
        case .hopeless: return Image("Hopeless")
        case .indifferent: return Image("Indifferent")
        case .irritated: return Image("Irritated")
        case .jealous: return Image("Jealous")
        case .joyful: return Image("Joyful")
        case .lonely: return Image("Lonely")
        case .overwhelmed: return Image("Overwhelmed")
        case .passionate: return Image("Passionate")
        case .peaceful: return Image("Peaceful")
        case .proud: return Image("Proud")
        case .relieved: return Image("Relieved")
        case .sad: return Image("Sad")
        case .satisfied: return Image("Satisfied")
        case .scared: return Image("Scared")
        case .stressed: return Image("Stressed")
        case .surprised: return Image("Surprised")
        case .worried: return Image("Worried")
        @unknown default: return Image("Happy")
        }
    }

    var level: MoodLevel {
        switch self {
        case .excited, .joyful, .amazed, .grateful, .proud, .hopeful, .passionate:
            return .veryPositive

        case .happy, .confident, .satisfied, .relieved, .amused, .brave, .surprised:
            return .positive

        case .content, .calm, .peaceful, .indifferent:
            return .neutral

        case  .worried,
             .sad, .lonely, .disappointed, .discouraged,
             .drained, .frustrated, .annoyed, .irritated,
             .jealous, .embarrassed, .guilty:
            return .negative

        case .anxious, .angry, .scared, .hopeless, .ashamed, .disgusted, .overwhelmed, .stressed:
            return .veryNegative

        @unknown default:
            return .neutral
        }
    }

    var defaultValence: Double {
        switch level {
        case .veryNegative: return -0.8
        case .negative:     return -0.4
        case .neutral:      return  0.0
        case .positive:     return  0.4
        case .veryPositive: return  0.8
        }
    }
}

enum MoodPrivacy: String, CaseIterable, Codable, Identifiable {
    case `private`
    case friends
    case `public`

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .private:
            return "Private"
        case .friends:
            return "Friends"
        case .public:
            return "Public"
        }
    }

    var icon: String {
        switch self {
        case .private:
            return "lock.fill"
        case .friends:
            return "person.2.fill"
        case .public:
            return "globe"
        }
    }
}
