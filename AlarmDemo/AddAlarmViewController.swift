//
//  AddAlarmViewController.swift
//  AlarmDemo
//
//  Created by Arpit iOS Dev. on 24/06/24.
//

import UIKit

protocol AddAlarmDelegate: AnyObject {
    func didSaveAlarm(date: Date)
}

class AddAlarmViewController: UIViewController {
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    weak var delegate: AddAlarmDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.datePickerMode = .dateAndTime
    }
    
    @IBAction func cancel(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: UIButton) {
        delegate?.didSaveAlarm(date: datePicker.date)
        dismiss(animated: true, completion: nil)
    }
}
