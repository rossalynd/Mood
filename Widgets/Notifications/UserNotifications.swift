/// import UserNotifications

//func scheduleMoodReminder(body: String, identifier: String = UUID().uuidString) async throws {
 //   let center = UNUserNotificationCenter.current()

//    //let content = UNMutableNotificationContent()
//    content.title = "Mood check-in"
//    content.body = body
//    content.sound = .default
//
//    var components = DateComponents()
//    components.hour = 18
//    components.minute = 0

 //   let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
 //   let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

 //   try await center.add(request)
//}
///
