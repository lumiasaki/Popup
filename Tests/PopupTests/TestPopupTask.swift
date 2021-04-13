//
//  TestPopupTask.swift
//  Popup
//
//  Created by zhutianren on 2021/1/25.
//

import Foundation
import Popup

class TestPopupTask: PopupTask {
    
    enum State {
        case idle
        case show
        case canceled
        case dismissed
    }
    
    weak var manager: Popup.Manager?
    
    var taskDescription: String
    
    var priority: Int
    
    var isCanceled: Bool = false
    
    var state: State = .idle
    
    var onShow: (() -> Void)?
    
    init(priority: Int, description: String) {
        self.priority = priority
        self.taskDescription = description
    }
    
    func render() {
        state = .show
    }
}

extension TestPopupTask {
    
    func didShow() {
        onShow?()
    }
    
    func didCanceled() {
        state = .canceled
    }
    
    func didDismiss() {
        state = .dismissed
    }
}
