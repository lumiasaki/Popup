//
//  ViewController.swift
//  Example
//
//  Created by zhutianren on 2021/1/25.
//

import UIKit
import Popup

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let task1 = ExamplePopupTask(priority: 0, description: "Advertisement Popup", viewController: self)
        task1.willShowBlock = { task in
            task.isCanceled = false
        }
        let task2 = ExamplePopupTask(priority: 1, description: "Pause Popup", viewController: self)
        task2.willShowBlock = { task in
            task.isCanceled = false
        }
        let task3 = ExamplePopupTask(priority: 2, description: "Notification Popup", viewController: self)
        task3.willShowBlock = { task in
            task.isCanceled = false
        }
        
        do {
            try Popup.Manager.shared.add(task: task1)
            try Popup.Manager.shared.add(task: task2)
            try Popup.Manager.shared.add(task: task3)
        } catch {
            print(error)
        }
    }


}

