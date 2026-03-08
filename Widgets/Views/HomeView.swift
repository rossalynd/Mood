import SwiftUI
import HealthKit
import WidgetKit

@available(iOS 26.0, *)
struct HomeView: View {
    @Binding var path: NavigationPath
    @Binding var selectedTab: MoodTab
    @EnvironmentObject var moodStore: HealthKitMoodStore
    @EnvironmentObject var router: DeepLinkRouter

    
    @State private var moods: [HKStateOfMind] = []
    @Binding var showAddMood: Bool


    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isLoading = false

    private var latestMood: HKStateOfMind? {
        moods.max(by: { $0.startDate < $1.startDate })
    }

    private var hasMoodLoggedToday: Bool {
        guard let latestMood else { return false }
        return Calendar.current.isDateInToday(latestMood.startDate)
    }

    @MainActor
    private func loadMoods() async {
        isLoading = true
        defer { isLoading = false }

        do {
            
                moods = try await moodStore.fetchRecentMoods(limit: 50)

                if let latest = latestMood {
                    let assetName = latest.labels.first?.displayName ?? "Happy"
                    SharedMoodCache.writeLatest(assetName: assetName, date: latest.startDate, color: latest.labels.first?.level.color ?? .green)
                    
                }
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: Placeholder state
    @State private var friendsEnabled = false
    @State private var hasFriends = false
    @State private var hasTags = false
    @State private var showMemoryCard = false


    @State private var currentMoodEmoji = "😌"
    @State private var currentMoodLabel = "Calm"
    @State private var lastLoggedText = "Last logged: 2h ago"
    @State private var notePreview: String? = "Had a great workout…"

    private var quickLogMoods: [MoodItem] {
        let quickLabels: [HKStateOfMind.Label] = [
            .happy,
            .calm,
            .sad,
            .angry,
            .drained,
            .excited
        ]

        return quickLabels.map { MoodItem(label: $0) }
    }

    private let tools: [MoodToolItem] = [
        .init(title: "Mood Boost", systemImage: "sparkles", path: .breathing ),
        .init(title: "Breathe", systemImage: "leaf.fill", path: .breathing),
        .init(title: "Affirmation", systemImage: "quote.bubble", path: .breathing)
    ]

    private let cardRadius: CGFloat = 22

    var body: some View {
        ZStack {
            LiquidBackdrop()
                .ignoresSafeArea()
                
            ScrollView {
                
                VStack(spacing: 16) {
                    Color.clear.frame(height: 4)
                    HStack(alignment: .top,spacing: 5){
                        currentMoodCard
                        todaysSnapshotCard
                    }
                    quickLogRow
                    
                    weeklyTrendCard
                    friendsSection
                    moodToolsGrid
                    memoriesCard
                    recentEntriesPreview
                }
                .padding(.horizontal)
                .padding(.bottom, 140) // leaves room for the floating tab bar
               
                
            }
            
            
        }
        
        
        
        .navigationBarHidden(true)
        .safeAreaInset(edge: .top) {
                header
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(.regularMaterial)
            
                    
                    
            }
        
        .task {
            do {
                try await moodStore.requestAuth()
                await loadMoods()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        .onChange(of: router.openAddMood) { _, isPresented in
            if !isPresented {
                Task { await loadMoods() }
            }
        }
        .alert("Health Access", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .overlay {
            if isLoading && moods.isEmpty {
                ProgressView()
            }
        }
        
    }

    // MARK: Header (push instead of sheet)

    private var header: some View {
        HStack(spacing: 10) {
            Image("Logo")
                .resizable()
                .frame(width: 35, height: 35)
            Image("instamood")
                .resizable()
                .frame(width: 130, height: 35)

            Spacer()

            
            StreakPill()
                .task {
                    await moodStore.refresh()
                }
            Button {
                path.append(HomeRoute.settings)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(Font.system(size: 20))
                    .foregroundColor(.primary)
            }

           

            
        }.padding(10)
        
     
        
    }

    // MARK: 2) Current Mood Card

    private var currentMoodCard: some View {
        Button {
            path.append(HomeRoute.logMood)
            router.openAddMood = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    
                    ZStack {
                        Rectangle().frame(width: 120, height: 120)
                            .foregroundStyle(Color(.clear))
                        VStack(spacing: 4) {
                            if !hasMoodLoggedToday {
                                
                                Image("Content")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .clipped()
                                    .foregroundStyle(.primary)
                                    .opacity(0.5)
                                Text("No Logs")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("Tap to Extend Streak")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                
                            } else {
                                ZStack{
                                    Circle()
                                        .frame(width: 60, height: 60)
                                        .foregroundStyle(latestMood?.labels.first?.level.color ?? .clear)
                                        .opacity(0.3)
                                    Image(latestMood?.labels.first?.displayName ?? "happy")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundStyle(latestMood?.labels.first?.level.color ?? .green)
                                        .clipped()
                                        
                                        
                                }
                                Text(latestMood?.labels.first?.displayName ?? "Happy")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                Text(latestMood?.startDate.formatted(date: .omitted, time: .shortened) ?? "test")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                            }
                            
                        }.frame(width: 120)
                        
                    }
                }
                
                
                
                
                
                
                .padding()
                .liquidGlassCard(cornerRadius: cardRadius, material: .thin)
                Spacer()
            }
        }.foregroundStyle(.primary)
            .buttonStyle(.borderless)
    }

    // MARK: 3) Quick Log Row

    private var quickLogRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How are you feeling?")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(quickLogMoods) { mood in
                        Button {
                            Task {
                                await quickLog(mood)
                            }
                        } label: {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 34, height: 34)
                                        .overlay(
                                            Circle()
                                                .stroke(.white.opacity(0.15), lineWidth: 1)
                                        )

                                    Image(mood.displayName)
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 18, height: 18)
                                        .foregroundStyle(mood.level.color)
                                }

                                Text(mood.displayName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 60, height: 60)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 6)
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
                        .accessibilityLabel("Quick log \(mood.displayName)")
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: 4) Today’s Snapshot
    private var todaySnapshot: MoodDaySnapshot {
        moodStore.todaySnapshot
    }

    private var todayAverageText: String {
        todaySnapshot.averageLabelText
    }

    private var todayCheckInCountText: String {
        "\(todaySnapshot.checkInCount)"
    }

    private var todayTopTriggerText: String {
        todaySnapshot.topLabelName ?? "None"
    }

    private var todayLastLogText: String {
        guard let date = todaySnapshot.lastLogDate else { return "No logs" }
        return abbreviatedRelativeDate(from: date)
    }
    
    private func abbreviatedRelativeDate(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private var todaysSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)

            VStack(spacing: 12) {
                snapshotRow(
                    title: "Average",
                    systemImage: "waveform.path.ecg",
                    value: todayAverageText
                )

                snapshotRow(
                    title: "Check-ins",
                    systemImage: "checkmark.circle",
                    value: todayCheckInCountText
                )

                if hasTags {
                    snapshotRow(
                        title: "Top trigger",
                        systemImage: "flame",
                        value: todayTopTriggerText
                    )
                } else {
                    snapshotRow(
                        title: "Streak",
                        systemImage: "bolt",
                        value: "\(moodStore.streak.current) day\(moodStore.streak.current == 1 ? "" : "s")"
                    )

                    snapshotRow(
                        title: "Last log time",
                        systemImage: "clock",
                        value: todayLastLogText
                    )
                }
            }
            .font(.subheadline)
        }
        .padding(.top, 5)
        .padding(.leading, 10)
    }

    private func snapshotRow(title: String, systemImage: String, value: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: 5) Weekly Trend

    private var weeklyTrendCard: some View {
        Button {
            // Either push insights OR switch tabs:
            // path.append(HomeRoute.insights)
            selectedTab = .insights
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("This week")
                        .font(.headline)
                    Spacer()
                    
                }

                CurrentWeekMoodBarGraph()
                   
                    .frame(height: 150)
                    
                    

                
            }
        }
        .buttonStyle(.plain)
        .padding()
        .liquidGlassCard(cornerRadius: cardRadius, material: .thinMaterial)
        .accessibilityLabel("Weekly trend. Tap to view statistics.")
    }

    // MARK: 6) Friends

    @ViewBuilder
    private var friendsSection: some View {
        if friendsEnabled {
            if hasFriends {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Friends")
                            .font(.headline)
                        Spacer()
                        Button { } label: {
                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundStyle(.secondary)
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(0..<8, id: \.self) { _ in
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 44, height: 44)
                                        .overlay(Circle().stroke(.white.opacity(0.14), lineWidth: 1))
                                        .overlay(Text("🙂"))
                                    Text("Name")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 60)
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        Button { } label: {
                            Label("Send booster", systemImage: "paperplane")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button { } label: {
                            Label("Share your mood", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .font(.subheadline)
                }
                .padding()
                .liquidGlassCard(cornerRadius: cardRadius, material: .ultraThinMaterial)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Add friends (optional)")
                        .font(.headline)

                    Text("Keep it simple—track your mood first. Friends are here when you want them.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        Button { } label: {
                            Text("Invite").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button { } label: {
                            Text("Not now").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .liquidGlassCard(cornerRadius: cardRadius, material: .ultraThinMaterial)
            }
        }
    }

    // MARK: 7) Mood Tools

    private var moodToolsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick reset")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(tools) { tool in
                    Button {
                        
                        path.append(tool.path)
                        
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: tool.systemImage)
                                .font(.title3)
                            Text(tool.title)
                                .font(.subheadline.weight(.medium))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, minHeight: 74)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
                }
            }
        }
    }

    // MARK: 8) Memories

    @ViewBuilder
    private var memoriesCard: some View {
        if showMemoryCard {
            Button { } label: {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Memory")
                        .font(.headline)

                    Text("1 month ago you felt ✨ Excited")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(height: 72)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(.white.opacity(0.12), lineWidth: 1)
                        )
                        .overlay(
                            Text("Photo / note preview placeholder")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .buttonStyle(.plain)
            .padding()
            .liquidGlassCard(cornerRadius: cardRadius, material: .thinMaterial)
        }
    }

    // MARK: Recent

    

            private var recentEntriesPreview: some View {
                RecentMoodsPreviewCard {
                    path.append(HomeRoute.recentMoods)
                }
            }
    
    
    @MainActor
    private func quickLog(_ mood: MoodItem) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await moodStore.requestAuth()
            try await moodStore.saveMood(
                valence: mood.label.defaultValence,
                kind: .momentaryEmotion,
                labels: [mood.label]
            )

            SharedMoodCache.writeLatest(
                assetName: mood.displayName,
                date: Date(),
                color: mood.level.color
            )

            WidgetCenter.shared.reloadTimelines(ofKind: "MoodWidget")
            await loadMoods()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("Quick log failed:", error)
        }
    }
}


@available(iOS 26.0, *)
#Preview {
    
    RootShellView()
        .environmentObject(HealthKitMoodStore())
        .environmentObject(DeepLinkRouter())
        .environmentObject(AuthService())
      
}

