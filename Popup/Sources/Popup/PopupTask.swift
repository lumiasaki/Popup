//
//  PopupTask.swift
//  Popup
//
//  Created by zhutianren on 2021/1/22.
//

import Foundation

public protocol PopupTask: class, PopupTaskLifeCycle, CustomStringConvertible, CustomDebugStringConvertible {
    
    var manager: Popup.Manager? { get set }
    
    /// custom description for a task
    var taskDescription: String { get set }
    
    /// priority, ascend order
    var priority: Int { get }
    
    /// cancel flag, if a task wants to cancel itself, it could flag `isCanceled` true during `willShow()`
    var isCanceled: Bool { get set }
    
    /// when the user interaction is done for the popup, it responsible for invoking this method to continue the loop
    func finishAction(_ task: PopupTask)
    
    /// a right place to show popup user interface, the task will not restrict the way how you show it
    func render()
}

extension PopupTask {
    
    public var description: String { taskDescription }
    public var debugDescription: String { taskDescription }
}

public protocol PopupTaskLifeCycle {
    
    func willShow()
    func didCanceled()
    func didShow()
    func willDismiss()
    func didDismiss()
}

public extension PopupTaskLifeCycle {
    
    func willShow() { }
    func didCanceled() { }
    func didShow() { }
    func willDismiss() { }
    func didDismiss() { }
}

/// Type erasure type for `PopupTask`
public class AnyPopupTask: PopupTask {
    
    public let base: PopupTask
    
    init(_ base: PopupTask) {
        self.base = base
    }
    
    public weak var manager: Popup.Manager? {
        get { base.manager }
        set { base.manager = newValue }
    }
    
    public var taskDescription: String {
        get { base.taskDescription }
        set { base.taskDescription = newValue }
    }
    public var priority: Int { base.priority }
    public var isCanceled: Bool {
        get { base.isCanceled }
        set { base.isCanceled = newValue}
    }
    
    public func finishAction(_ task: PopupTask) {
        base.finishAction(task)
    }
    
    public func render() {
        base.render()
    }
    
    // popup task life cycle
    public func willShow() {
        base.willShow()
    }
    
    public func didCanceled() {
        base.didCanceled()
    }
    
    public func didShow() {
        base.didShow()
    }
    
    public func willDismiss() {
        base.willDismiss()
    }
    
    public func didDismiss() {
        base.didDismiss()
    }
}

extension AnyPopupTask: Comparable {
    
    public static func < (lhs: AnyPopupTask, rhs: AnyPopupTask) -> Bool {
        lhs.priority < rhs.priority
    }
    
    public static func == (lhs: AnyPopupTask, rhs: AnyPopupTask) -> Bool {
        lhs.priority == rhs.priority
    }
}

extension AnyPopupTask: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String { taskDescription }
    public var debugDescription: String { taskDescription }
}
