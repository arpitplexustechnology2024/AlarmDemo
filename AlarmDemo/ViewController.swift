//
//  ViewController.swift
//  AlarmDemo
//
//  Created by Arpit iOS Dev. on 24/06/24.
//

import UIKit
import UserNotifications

struct Alarm : Codable {
    var date: Date
    var isOn: Bool
    var notificationIdentifier: String
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddAlarmDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var alarms: [Alarm] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        requestNotificationPermission()
        
        // Load alarms from UserDefaults
               loadAlarms()

               // Reschedule alarms
               for alarm in alarms where alarm.isOn {
                   scheduleNotification(for: alarm)
               }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Permission granted")
            } else {
                print("Permission denied")
            }
        }
    }
    
    @IBAction func createAlarm(_ sender: UIBarButtonItem) {
        if let addAlarmVC = storyboard?.instantiateViewController(withIdentifier: "AddAlarmViewController") as? AddAlarmViewController {
            addAlarmVC.delegate = self
            present(addAlarmVC, animated: true, completion: nil)
        }
    }
    
    func didSaveAlarm(date: Date) {
        let identifier = UUID().uuidString
        let alarm = Alarm(date: date, isOn: true, notificationIdentifier: identifier)
        alarms.append(alarm)
        saveAlarms()
        scheduleNotification(for: alarm)
        tableView.reloadData()
    }
    
    func scheduleNotification(for alarm: Alarm) {
        let content = UNMutableNotificationContent()
        content.title = "Alarm"
        content.body = "Your alarm is ringing!"
        content.sound = .default

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: alarm.date)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: alarm.notificationIdentifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error)")
            } else {
                print("Notification scheduled: \(alarm.notificationIdentifier)")
                self.rescheduleRepeatingNotification(alarm: alarm)
            }
        }
    }
    
    func rescheduleRepeatingNotification(alarm: Alarm) {
           guard alarm.isOn else { return }

           let content = UNMutableNotificationContent()
           content.title = "Alarm"
           content.body = "Your repeating alarm is ringing!"
           content.sound = .default

           let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2 * 60, repeats: false)
           let newIdentifier = UUID().uuidString
           let request = UNNotificationRequest(identifier: newIdentifier, content: content, trigger: trigger)

           UNUserNotificationCenter.current().add(request) { [weak self] error in
               if let error = error {
                   print("Error adding repeating notification: \(error.localizedDescription)")
               } else {
                   print("Repeating notification scheduled")
                   if alarm.isOn {
                       DispatchQueue.main.asyncAfter(deadline: .now() + 2 * 60) {
                           if alarm.isOn {
                               self?.rescheduleRepeatingNotification(alarm: alarm)
                           }
                       }
                   }
               }
           }
       }

    
    func cancelNotification(for alarm: Alarm) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarm.notificationIdentifier])
        print("Notification cancelled")
    }
    
    func saveAlarms() {
           if let encoded = try? JSONEncoder().encode(alarms) {
               UserDefaults.standard.set(encoded, forKey: "alarms")
           }
       }

       func loadAlarms() {
           if let savedAlarms = UserDefaults.standard.object(forKey: "alarms") as? Data {
               if let decodedAlarms = try? JSONDecoder().decode([Alarm].self, from: savedAlarms) {
                   alarms = decodedAlarms
               }
           }
       }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alarms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AlarmTableViewCell", for: indexPath) as? AlarmTableViewCell else {
            return UITableViewCell()
        }
        let alarm = alarms[indexPath.row]
        cell.timeLabel.text = DateFormatter.localizedString(from: alarm.date, dateStyle: .none, timeStyle: .short)
        cell.alarmSwitch.setOn(alarm.isOn, animated: true)
        
        cell.switchChanged = { [weak self] isOn in
            self?.alarms[indexPath.row].isOn = isOn
            if isOn {
                self?.scheduleNotification(for: alarm)
            } else {
                self?.cancelNotification(for: alarm)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
           return true
       }

       func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
           if editingStyle == .delete {
               let alarm = alarms[indexPath.row]
               cancelNotification(for: alarm)
               alarms.remove(at: indexPath.row)
               saveAlarms()
               tableView.deleteRows(at: [indexPath], with: .fade)
           }
       }
}
