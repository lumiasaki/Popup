# Popup

## Motivation

Managing logic in an App is not an easy task, especially when our App is getting bigger and bigger with more and more collaborative teams. One business form that is common in our apps (especially in apps made by Chinese companies) is a pop-up or bubble in the full screen. Sometimes we use such popups to request responsive permissions from users in a more user-friendly way (e.g. requesting geolocation permissions), explaining in advance why we need the permission on a custom popup, and then showing the user the iOS permission popup to boost conversions. When there are more and more such custom popups, there may be multiple popups popping up on the screen at the same time, causing visual coverage between each other. Even in the same app, there are many ways to show full-screen popups to users due to business iteration, requirement development, team collaboration, etc. For example, some development teams choose to show them directly on the KeyWindow, and some choose to show them on the top-level ViewController, in short, there are very many possibilities to accomplish this business scenario in reality, and the way we use may vary, and it is even more difficult to solve the visual coverage of pop-ups caused by this reason.

## How to use

This framework currently supports SPM, you can simply add a dependency on this framework in Xcode to reach the integration purpose.

## Design details

![StateMachine](https://user-images.githubusercontent.com/6101691/124080913-7abe6f80-da7d-11eb-9b20-68f7710df04e.png)

Popup is a very tiny, and simple core logic of the tool library, because the design of the beginning to consider the view level to manage all the existing pop-ups, for the project being developed may be a very difficult thing, so the beginning of the positioning itself as a "pop-up task" manager. In fact, there is not any mandatory requirements on how popups are displayed on the View, and since all popup tasks are managed according to the priority, it is actually very lightweight to insert code to transform the old code to be managed by the popup queue and solve the conflicts between popups.

The logic used in Popup is a priority queue, and all tasks need to follow the `PopupTask` protocol, which represents a popup task, and the implementor needs to provide at least the priority of the task and the task description, and then implement `render` method, which needs to implement the logic of how to display the popup, which will be called when the popup will be displayed soon.

Popup also provides `isCanceled` flag to support some special scenarios where a popup may not be displayed when it should be, as long as the task implements the `willShow` method and implements its own judgment mechanism inside the method, for example, when the current top-level ViewController is a specific class , the popup should not be shown, at this time you can mark `isCanceled` as `true` within the method, the popup will not be popped up visually, and the subsequent queued popups get the chance to pop up.

When the queue inside the Popup is empty, as soon as a task is added to the Popup, the life cycle of the task is executed immediately, and if a higher priority popup is added to the queue before the first task has completed its display logic, it does not affect the current popup task either. In short, the priority queue only affects inactive popup tasks. If a popup task is already `active`, the popup will finish its lifecycle without being affected by other tasks. In addition, if a task sets the `isCanceled` flag to `true` before its `didShow` is called (usually using the logic implemented in `willShow` to determine this), the task will simply be discarded without any other processing (e.g. retrying) after executing its response lifecycle method while it is queued to the head of the queue.

Popup internally uses a state machine mechanism to manage the scheduling of tasks. When the queue is idle, it will always be in the `idle` state, and when a task is added to the queue, it will change the internal state to `active`, after that, in the corresponding handler function, a task will be taken out from the queue head as an active task, and the flow of state will continue, and finally when a task has finished showing the pop-up. The internal state will return to `idle` and wait for the next task to come. This mechanism is simple and efficient, with good abstraction and clear semantics.
