//
//  PopupManager.swift
//  Popup
//
//  Created by zhutianren on 2021/1/22.
//

import Foundation
import SwiftPriorityQueue

public enum Popup {
    
    public final class Manager {
        
        enum State {
            
            /// idle, means the queue is empty, when at least one task be added to the queue, the state will become active
            case idle
            
            /// active, which means the queue contains at least one task, the task with highest priority will be locate at the top
            case active
            
            /// indicates the active task will be executed soon, the active task could modify the `isCanceled` flag during this life-cycle. if the `isCanceled` flag is false, the state will be `inProgress`, otherwise `handleCancel`
            case handleShow
            
            /// current active task assign true to the `isCanceled` flag, the state will go to `active` as well
            case handleCancel
            
            /// the task is in process, waiting for `finishAction()` calls from the task
            case inProgress
            
            /// when the active task calls `finishAction()`, the state will become `handleDismiss`
            case handleDismiss
        }
        
        public static let shared: Manager = Manager()
        
        public var allTasks: [PopupTask] { queue.value.map { $0.base } }
        
        private var queue: Atomic<PriorityQueue<AnyPopupTask>> = Atomic(PriorityQueue())
        
        private var activeTask: AnyPopupTask? { queue.value.peek() }
        
        private(set) var state: State = .idle {
            willSet { print("popup manager state from \(state) to \(newValue)") }
        }
        
        public func add(task: PopupTask) {
            attachCapabilitiesToTask(task)
            
            queue.mutate { $0.push(AnyPopupTask(task)) }
            print("popup manager all tasks: \(String(describing: allTasks)))")
            
            becomeActiveIfNeeded()
        }
        
        private func becomeActiveIfNeeded() {
            // if the queue contains only one task, then the state becomes `active` from `idle`, otherwise, the state will not be changed
            guard queue.value.count == 1 else {
                return
            }
                    
            // it must be `idle` in this scenario
            guard state == .idle else {
                fatalError("the count of queue is 1 but state is not idle")
            }
            
            transit(to: .active)
        }
        
        private func attachCapabilitiesToTask(_ task: PopupTask) {
            task.finishAction = taskFinishAction
        }
        
        // Capability
        
        private func taskFinishAction(task: PopupTask) {
            guard let activeTask = activeTask, task === activeTask.base else {
                return
            }
            
            transit(to: .handleDismiss)
        }
    }
}

// MARK: - Validate State Transitioning

extension Popup.Manager.State {
    
    func canTransit(to state: Popup.Manager.State) -> Bool {
        switch (self, state) {
        case (.idle, .idle), (.idle, .active): return true
        case (.active, .handleShow), (.active, .idle): return true
        case (.handleShow, .inProgress), (.handleShow, .handleCancel): return true
        case (.handleCancel, .active): return true
        case (.inProgress, .inProgress), (.inProgress, .handleDismiss): return true
        case (.handleDismiss, .active): return true
        default:
            return false
        }
    }
}

// MARK: - State Transitioning

extension Popup.Manager {
    
    func transit(to state: Popup.Manager.State) {
        guard self.state.canTransit(to: state) else {
            fatalError("cannot transit from state: \(self.state) to state: \(state)")
        }
        
        let currentState = self.state
        
        self.state = state
        
        switch (currentState, state) {
        // nop
        case (.idle, .idle): ()
        case (.inProgress, .inProgress): ()
            
        case (_, .idle): handleToIdle()
        case (_, .active): handleToActive()
        case (_, .handleShow): handleToShow()
        case (_, .handleCancel): handleToCancel()
        case (_, .inProgress): handleToInProgress()
        case (_, .handleDismiss): handleToDismiss()
        }
    }
    
    private func handleToIdle() {
        // feel free to transit to idle, it will not cause calling-cycle
        transit(to: .idle)
    }
    
    private func handleToActive() {
        // if there is not any tasks in the queue, go back to `idle` state
        guard let _ = activeTask else {
            transit(to: .idle)
            return
        }
                
        // otherwise, `show` the active task
        transit(to: .handleShow)
    }
    
    private func handleToShow() {
        guard let activeTask = activeTask else {
            fatalError("does not contain any active tasks in the queue")
        }
                
        // notify `willShow` event on the task
        activeTask.willShow()
                
        // if the task modified the `isCanceled` flag, enter `handleCancel` procedure, otherwise, enter `inProgress`
        activeTask.isCanceled ? transit(to: .handleCancel) : transit(to: .inProgress)
    }
    
    private func handleToCancel() {
        guard let activeTask = activeTask else {
            fatalError("transit to cancel but active task is nil")
        }
                
        // active task calls `cancel()`, should remove the task in the queue
        queue.mutate { $0.remove(activeTask) }
        
        activeTask.didCanceled()
        
        transit(to: .active)
    }
    
    private func handleToInProgress() {
        guard let activeTask = activeTask else {
            fatalError("transit to in progress but active task is nil")
        }
        
        activeTask.render()
        activeTask.didShow()
        
        // feel free to transit to in progress, it will not cause calling-cycle
        transit(to: .inProgress)
    }
    
    private func handleToDismiss() {
        guard let activeTask = activeTask else {
            fatalError("transit to dismiss but no active task in the queue")
        }
        
        activeTask.willDismiss()
        
        queue.mutate { let _ = $0.pop() }
                
        activeTask.didDismiss()
        
        transit(to: .active)
    }
}

// MARK: - Objective-C Interoperability

extension Popup.Manager {
    
    public func add(task: AnyObject) {
        guard let task = task as? PopupTask else {
            fatalError()
        }
        
        add(task: task)
    }
}
