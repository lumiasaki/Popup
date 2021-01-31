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
        
        /// State for Popup Manager
        public enum State {
            
            /// idle, means the queue is empty, when at least one task be added to the queue, the state will become active
            case idle
            
            /// active, which means the queue contains at least one task, the task with highest priority will be locate at the top
            case active
            
            /// indicates the active task will be executed soon, the active task could modify the `isCanceled` flag during this life-cycle. if the `isCanceled` flag is false, the state will be `inProgress`, otherwise `handleCancel`
            case handleShow
            
            /// current active task assign true to the `isCanceled` flag, the state will go to `active` as well
            case handleCancel
            
            /// the task is in process, waiting for `resignFocus()` calls from the task
            case inProgress
            
            /// when the active task calls `resignFocus()`, the state will become `handleDismiss`
            case handleDismiss
        }
        
        /// Errors for Popup Manager
        public enum Error: Swift.Error {
            
            /// throwing this error while adding a task with an exists priority
            case containsSamePriority
            
            /// throwing this error while trying to finish an inactive task
            case finishInactiveTask
        }
        
        public static let shared: Manager = Manager()
        
        public var allTasks: [PopupTask] {
            let tasksInQueue = queue.value.map { $0.base }
            
            if let activeTask = activeTask {
                return [activeTask.base] + tasksInQueue
            }
            
            return tasksInQueue
        }
        
        private var queue: Atomic<PriorityQueue<AnyPopupTask>> = Atomic(PriorityQueue())
        
        private var activeTask: AnyPopupTask?
        
        private var prioritySet: Set<Int> = Set()
        
        private(set) var state: State = .idle {
            willSet { print("popup manager state from \(state) to \(newValue)") }
        }
        
        public func add(task: PopupTask) throws {
            guard !prioritySet.contains(task.priority) else {
                throw Error.containsSamePriority
            }
            
            task.manager = self
            prioritySet.insert(task.priority)
            
            queue.mutate { $0.push(AnyPopupTask(task)) }
            print("popup manager all tasks: \(String(describing: allTasks)))")
            
            becomeActiveIfNeeded()
        }
        
        private func becomeActiveIfNeeded() {
            // if the all tasks ( includes the active task ) contains only one task, then the state becomes `active` from `idle`, otherwise, the state will not be changed
            guard allTasks.count == 1 else {
                return
            }
                    
            // it must be `idle` in this scenario
            guard state == .idle else {
                fatalError("the count of allTasks is 1 but state is not idle")
            }
            
            transit(to: .active)
        }
        
        // Capability
        
        fileprivate func taskResignFocusAction(task: PopupTask) throws {
            guard let activeTask = activeTask, task === activeTask.base else {
                throw Error.finishInactiveTask
            }
            
            transit(to: .handleDismiss)
        }
    }
}

// MARK: - Extension on PopupTask

public extension PopupTask {
    
    func resignFocus() throws {
        try self.manager?.taskResignFocusAction(task: self)
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
        guard queue.value.count > 0 else {
            transit(to: .idle)
            return
        }
        
        // fetch one from queue
        queue.mutate { self.activeTask = $0.pop() }
                
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
        
        activeTask.didCanceled()
        
        // active task calls `cancel()`, should assign the self.activeTask to nil
        prioritySet.remove(activeTask.priority)
        self.activeTask = nil
        
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
        activeTask.didDismiss()
        
        prioritySet.remove(activeTask.priority)
        self.activeTask = nil
        
        transit(to: .active)
    }
}
