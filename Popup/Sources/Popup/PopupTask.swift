//
//  PopupTask.swift
//  Popup
//
//  Created by zhutianren on 2021/1/22.
//

import Foundation

public protocol PopupTask: class, PopupTaskLifeCycle, CustomStringConvertible, CustomDebugStringConvertible {
    
    var taskDescription: String { get }
    var priority: Int { get }
    var isCanceled: Bool { get set }
    
    var finishAction: (PopupTask) -> Void { get set }
    
    func render()
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

public class AnyPopupTask: PopupTask {
    
    public let base: PopupTask
    
    init(_ base: PopupTask) {
        self.base = base
    }
    
    public var taskDescription: String { base.taskDescription }    
    public var priority: Int { base.priority }
    public var isCanceled: Bool {
        get { base.isCanceled }
        set { base.isCanceled = newValue}
    }
    public var finishAction: (PopupTask) -> Void {
        get { base.finishAction }
        set { base.finishAction = newValue }
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
