import SwiftUI
import Foundation

@available(iOS 26.0, *)
struct AccountSetupView: View {
    var onComplete: ((AccountSetupData) -> Void)?

    @Environment(\.dismiss) private var dismiss

    // MARK: - Flow
    @State private var currentStep: SetupStep = .name

    // MARK: - State
    @State private var username: String = ""
    @State private var displayName: String = ""
    @State private var selectedEmotionSymbol: String? = nil
    @State private var friendQuery: String = ""
    @State private var moodGoalPerWeek: Int = 5
    @State private var reminderTimes: [Date] = []
    @State private var newReminderTime: Date =
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()

    @State private var isSaving: Bool = false
    @State private var showValidationError: Bool = false
    @State private var validationMessage: String = ""

    private let emotionSymbols: [String] = [
        "sun.max.fill",
        "cloud.drizzle.fill",
        "cloud.fill",
        "moon.stars.fill",
        "sparkles",
        "heart.fill",
        "bolt.heart.fill",
        "leaf.fill",
        "flame.fill",
        "drop.fill"
    ]

    private let iconColumns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: 14),
        count: 3
    )

    var body: some View {
        NavigationStack {
            ZStack {
                setupBackground

                VStack(spacing: 0) {
                    topBar
                    progressSection

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            stepContent
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 140)
                    }

                    bottomActionBar
                }
            }
            .navigationBarHidden(true)
            .alert("Please check your info", isPresented: $showValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }
}

// MARK: - Step Model
@available(iOS 26.0, *)
private enum SetupStep: Int, CaseIterable {
    case name
    case emotion
    case friends
    case goal
    case reminders
    case review

    var title: String {
        switch self {
        case .name: return "Your Profile"
        case .emotion: return "Pick Your Vibe"
        case .friends: return "Add Friends"
        case .goal: return "Set a Goal"
        case .reminders: return "Daily Reminders"
        case .review: return "Review"
        }
    }

    var subtitle: String {
        switch self {
        case .name:
            return "Choose the name people will see and the username they can find."
        case .emotion:
            return "Pick the symbol that best matches your energy."
        case .friends:
            return "Optionally connect with friends now, or skip for later."
        case .goal:
            return "Set a realistic weekly mood check-in target."
        case .reminders:
            return "Choose times to gently remind yourself to log."
        case .review:
            return "Make sure everything looks right before finishing."
        }
    }

    var nextButtonTitle: String {
        self == .review ? "Save and Continue" : "Continue"
    }

    var isLast: Bool {
        self == .review
    }

    var isFirst: Bool {
        self == .name
    }

    var progressValue: Double {
        Double(rawValue + 1) / Double(Self.allCases.count)
    }

    var previous: SetupStep? {
        SetupStep(rawValue: rawValue - 1)
    }

    var next: SetupStep? {
        SetupStep(rawValue: rawValue + 1)
    }
}

// MARK: - Layout
@available(iOS 26.0, *)
private extension AccountSetupView {
    var setupBackground: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color.accentColor.opacity(0.08),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    var topBar: some View {
        HStack {
            Button {
                if let previous = currentStep.previous {
                    currentStep = previous
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: currentStep.isFirst ? "xmark" : "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Set Up Account")
                .font(.headline)

            Spacer()

            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }

    var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(currentStep.title)
                    .font(.title2.weight(.bold))

                Spacer()

                Text("Step \(currentStep.rawValue + 1) of \(SetupStep.allCases.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: currentStep.progressValue)
                .progressViewStyle(.linear)

            Text(currentStep.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    var stepContent: some View {
        switch currentStep {
        case .name:
            nameStepView
        case .emotion:
            emotionStepView
        case .friends:
            friendsStepView
        case .goal:
            goalStepView
        case .reminders:
            remindersStepView
        case .review:
            reviewStepView
        }
    }

    var bottomActionBar: some View {
        VStack(spacing: 12) {
            Button {
                handlePrimaryAction()
            } label: {
                Group {
                    if isSaving {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Saving...")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    } else {
                        Text(currentStep.nextButtonTitle)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                }
                .background(canProceed(for: currentStep) ? Color.accentColor : Color.gray.opacity(0.25))
                .foregroundStyle(canProceed(for: currentStep) ? Color.white : Color.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canProceed(for: currentStep) || isSaving)

            if !currentStep.isLast && currentStep != .name {
                Button("Skip this step") {
                    moveForward()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 20)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Step Views
@available(iOS 26.0, *)
private extension AccountSetupView {
    var nameStepView: some View {
        premiumCard {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(
                    icon: "person.crop.circle.fill",
                    title: "Tell us about you",
                    subtitle: "This helps personalize your account."
                )

                VStack(spacing: 16) {
                    premiumTextField(
                        title: "Display name",
                        placeholder: "Rosie",
                        text: $displayName,
                        contentType: .name,
                        autocapitalization: .words
                    )

                    premiumTextField(
                        title: "Username",
                        placeholder: "rosieomarrow",
                        text: $username,
                        contentType: .username,
                        autocapitalization: .never
                    )
                }
            }
        }
    }

    var emotionStepView: some View {
        premiumCard {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(
                    icon: "sparkles",
                    title: "Choose your default icon",
                    subtitle: "This can represent your mood identity in the app."
                )

                LazyVGrid(columns: iconColumns, spacing: 14) {
                    ForEach(emotionSymbols, id: \.self) { symbol in
                        emotionIconButton(for: symbol)
                    }
                }
            }
        }
    }

    var friendsStepView: some View {
        premiumCard {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(
                    icon: "person.2.fill",
                    title: "Find your people",
                    subtitle: "Search by handle or email to connect later."
                )

                premiumTextField(
                    title: "Search or invite",
                    placeholder: "@friend or email@example.com",
                    text: $friendQuery,
                    contentType: .emailAddress,
                    autocapitalization: .never
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Suggestions")
                        .font(.headline)

                    Text("Search results and invites will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    var goalStepView: some View {
        premiumCard {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(
                    icon: "target",
                    title: "Set your weekly goal",
                    subtitle: "Aim for consistency, not perfection."
                )

                VStack(spacing: 16) {
                    Text("\(moodGoalPerWeek)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)

                    Text("entries per week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Stepper("Target entries", value: $moodGoalPerWeek, in: 1...21)
                        .padding()
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    var remindersStepView: some View {
        premiumCard {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(
                    icon: "bell.badge.fill",
                    title: "Set reminder times",
                    subtitle: "Choose moments in your day to check in."
                )

                HStack(spacing: 12) {
                    DatePicker(
                        "Reminder Time",
                        selection: $newReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        addReminderTime(newReminderTime)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 44, height: 44)
                            .background(Color.accentColor, in: Circle())
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))

                if reminderTimes.isEmpty {
                    Text("No reminders yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(reminderTimes.enumerated()), id: \.offset) { index, time in
                            HStack {
                                Label {
                                    Text(time, style: .time)
                                        .font(.headline)
                                } icon: {
                                    Image(systemName: "clock.fill")
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button(role: .destructive) {
                                    removeReminder(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.plain)
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }
        }
    }

    var reviewStepView: some View {
        premiumCard {
            VStack(alignment: .leading, spacing: 18) {
                stepHeader(
                    icon: "checkmark.seal.fill",
                    title: "Review your setup",
                    subtitle: "Everything looks ready."
                )

                reviewRow(title: "Display name", value: trimmedDisplayName)
                reviewRow(title: "Username", value: "@\(trimmedUsername)")
                reviewRow(title: "Mood icon", value: selectedEmotionSymbol ?? "Not selected")
                reviewRow(title: "Weekly goal", value: "\(moodGoalPerWeek) entries")
                reviewRow(
                    title: "Reminders",
                    value: reminderTimes.isEmpty
                    ? "None"
                    : reminderTimes.map { timeString(from: $0) }.joined(separator: ", ")
                )
            }
        }
    }
}

// MARK: - Reusable Views
@available(iOS 26.0, *)
private extension AccountSetupView {
    func premiumCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 20, y: 10)
    }

    func stepHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.14))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.title3.weight(.bold))

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    func premiumTextField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType?,
        autocapitalization: TextInputAutocapitalization
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            TextField(placeholder, text: text)
                .textContentType(contentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .padding()
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    func reviewRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .fontWeight(.semibold)

            Spacer(minLength: 12)

            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    func emotionIconButton(for symbol: String) -> some View {
        let isSelected = selectedEmotionSymbol == symbol

        Button {
            selectedEmotionSymbol = symbol
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
                        .frame(height: 84)

                    Image(systemName: symbol)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                }

                Text(symbolLabel(for: symbol))
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Derived Values
@available(iOS 26.0, *)
private extension AccountSetupView {
    var trimmedUsername: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func canProceed(for step: SetupStep) -> Bool {
        switch step {
        case .name:
            return !trimmedUsername.isEmpty && !trimmedDisplayName.isEmpty
        case .emotion:
            return selectedEmotionSymbol != nil
        case .friends:
            return true
        case .goal:
            return moodGoalPerWeek >= 1
        case .reminders:
            return true
        case .review:
            return canSave
        }
    }

    var canSave: Bool {
        !trimmedUsername.isEmpty &&
        !trimmedDisplayName.isEmpty &&
        selectedEmotionSymbol != nil
    }

    func symbolLabel(for symbol: String) -> String {
        switch symbol {
        case "sun.max.fill": return "Bright"
        case "cloud.drizzle.fill": return "Tender"
        case "cloud.fill": return "Calm"
        case "moon.stars.fill": return "Reflective"
        case "sparkles": return "Inspired"
        case "heart.fill": return "Warm"
        case "bolt.heart.fill": return "Intense"
        case "leaf.fill": return "Grounded"
        case "flame.fill": return "Driven"
        case "drop.fill": return "Soft"
        default: return "Mood"
        }
    }

    func timeString(from date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}

// MARK: - Actions
@available(iOS 26.0, *)
private extension AccountSetupView {
    func handlePrimaryAction() {
        if currentStep.isLast {
            save()
        } else {
            moveForward()
        }
    }

    func moveForward() {
        guard canProceed(for: currentStep) else {
            showStepValidation()
            return
        }

        if let next = currentStep.next {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                currentStep = next
            }
        }
    }

    func showStepValidation() {
        switch currentStep {
        case .name:
            validationMessage = "Please enter both a display name and a username."
        case .emotion:
            validationMessage = "Please choose an emotion icon to continue."
        case .friends, .goal, .reminders, .review:
            validationMessage = "Please check your information and try again."
        }

        showValidationError = true
    }

    func addReminderTime(_ date: Date) {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard let hour = comps.hour, let minute = comps.minute else { return }

        let alreadyExists = reminderTimes.contains { existingDate in
            let existingHour = Calendar.current.component(.hour, from: existingDate)
            let existingMinute = Calendar.current.component(.minute, from: existingDate)
            return existingHour == hour && existingMinute == minute
        }
        guard !alreadyExists else { return }

        // ✅ Anchor the time to today's date (valid for Firestore Timestamp)
        if let normalized = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) {
            reminderTimes.append(normalized)
            reminderTimes.sort()
        }
    }

    func removeReminder(at index: Int) {
        guard reminderTimes.indices.contains(index) else { return }
        reminderTimes.remove(at: index)
    }

    func save() {
        guard canSave else {
            validationMessage = "Please enter a display name, a username, and choose an emotion icon."
            showValidationError = true
            return
        }

        isSaving = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isSaving = false

            let data = AccountSetupData(
                username: trimmedUsername,
                displayName: trimmedDisplayName,
                emotionSymbol: selectedEmotionSymbol,
                moodGoalPerWeek: moodGoalPerWeek,
                reminderTimes: reminderTimes.sorted()
            )

            onComplete?(data)
            dismiss()
        }
    }
}

// MARK: - Model
@available(iOS 26.0, *)
struct AccountSetupData {
    let username: String
    let displayName: String
    let emotionSymbol: String?
    let moodGoalPerWeek: Int
    let reminderTimes: [Date]
}

// MARK: - Preview
@available(iOS 26.0, *)
#Preview {
    AccountSetupView { data in
        print("Saved:", data.username, data.displayName, data.emotionSymbol ?? "none")
    }
}
