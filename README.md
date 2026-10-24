# SchoolAssistant

A native student planner that brings class schedules, assignment deadlines, and reminders into one app. Built with Swift, SwiftUI, SwiftData, EventKit, and UserNotifications.

## What it does

- **Organizes coursework:** associates assignments with classes, displays active work before completed work, and preserves completion history locally.
- **Simplifies schedule setup:** imports calendar events into weekly class schedules, groups recurring meeting times, and skips previously imported classes. Users review and edit selections before saving.
- **Automates deadline reminders:** applies three priority policies and cancels reminders when assignments are completed or deleted.
- **Prompts assignment capture:** sends weekly class-start notifications and end-of-class check-ins asking whether new work was assigned.
- **Supports flexible deadlines:** accepts an exact date and time or calculates a deadline from a number of weeks.

## Run locally

1. Open `SchoolAssistant.xcodeproj` in Xcode with SDKs supporting the project's configured deployment targets: iOS 27.0, macOS 27.0, or visionOS 27.0.
2. Select the SchoolAssistant scheme and a compatible run destination. Configure signing if running on a physical device.
3. Build and run, then enter a display name.
4. Open **My Classes → Add Class** to enter a schedule manually or import from Calendar. Select a class to add an assignment.
5. Allow notifications to receive reminders. Calendar access is required only for importing schedules.

## Reminder behavior

| Priority | Scheduled reminders |
| --- | --- |
| Low | 4 days before the deadline |
| Medium | 2 days before the deadline |
| High | 4 days before, plus 1 hour before the deadline |

For high-priority deadlines before 1 AM, the final reminder is at midnight; a midnight deadline uses the preceding minute. Past reminder times are skipped.

The scheduler selects the nearest reminders within a 64-request budget, accounting for other pending requests. It refreshes when the app becomes active and after relevant data changes. If the budget is exceeded, the app asks users to reopen it regularly to schedule later reminders.

## Implementation

- **SwiftUI:** onboarding, class management, calendar review, and assignment tracking.
- **SwiftData:** persistent class and assignment models, queries, and cascading assignment deletion when a class is removed.
- **EventKit:** calendar access, event grouping, duplicate filtering, and reviewable batch imports.
- **UserNotifications and Swift concurrency:** asynchronous scheduling, stable notification identifiers, and serialized refreshes to prevent overlapping updates from leaving an older schedule installed.

## Current scope

Calendar import is a one-time copy into weekly schedules. It leaves source events unchanged and excludes all-day, canceled, and overnight events. Changes in Calendar are not synchronized automatically.

The app stores coursework locally and requires no account or backend. Notification delivery depends on system permissions and settings.

See [RESUME.md](RESUME.md) for a concise project entry.
