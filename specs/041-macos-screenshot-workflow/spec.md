# Feature Specification: macOS-like Screenshot Workflow with Interactive Annotation and Notifications

**Feature Branch**: `041-macos-screenshot-workflow`

**Created**: 2026-11-16

**Status**: Draft

**Input**: User description: "Intègre Satty (Option A) avec le workflow scripté de l'option D, pour avoir un outil de capture d'écran proche de celui de macOS."

## Clarifications

### Session 2026-11-16

- **Q1 (Annotation Interaction Model)**: Deferred notification-first workflow (macOS pure behavior) selected. Every capture immediately saves to disk, copies to clipboard, and displays a desktop notification with thumbnail preview; the Satty annotation editor opens on demand when the user clicks the "Annotate" action on the notification.
- **Q2 (Keybinding Scheme)**: Standard Linux keybindings selected. Workflow replaces/enhances existing Niri shortcuts (`Print` for region capture, `Ctrl+Print` for full-screen capture, `Alt+Print` for active window capture).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fast Area & Screen Capture with Dual Destination (Priority: P1)

As a workstation user, I want to capture a selected rectangular region or the entire screen with a quick shortcut, so that the image is immediately copied to my clipboard and stored in a designated screenshots directory without interrupting my flow.

**Why this priority**: Core utility. The primary reason for taking a screenshot is either immediate pasting into a chat/document or archiving to disk. Having both happen instantly with zero friction replicates the baseline convenience of modern desktop OS environments.

**Independent Test**: Trigger an area capture, select a screen rectangle, and verify that the clipboard contains the captured bitmap and that a new timestamped file appears in the configured screenshots directory.

**Acceptance Scenarios**:

1. **Given** the user triggers an area capture, **When** they drag-select a rectangular region on screen, **Then** the screenshot image is copied to the system clipboard and saved to the user's screenshots directory in PNG format.
2. **Given** the user triggers a full-screen capture, **When** the shortcut is pressed, **Then** all active display content is captured, copied to the clipboard, and written to disk without prompt.
3. **Given** an area capture is initiated, **When** the user presses Escape or cancels selection, **Then** no file is written, the clipboard remains untouched, and no notification is triggered.

---

### User Story 2 - macOS-Style Thumbnail Notification with Quick Actions (Priority: P2)

As a workstation user, I want to see a temporary notification preview of the captured screenshot with actionable buttons, so that I can inspect the result, open the enclosing folder, delete the file, or launch an annotation editor on demand.

**Why this priority**: Replicates the signature macOS thumbnail experience. Users get immediate visual confirmation of the capture and can quickly decide whether to keep, open, discard, or edit the image without manually navigating the filesystem.

**Independent Test**: Take a screenshot and verify that a desktop notification appears displaying an image thumbnail and interactive action buttons ("Annotate / Edit", "Open Folder", "Delete").

**Acceptance Scenarios**:

1. **Given** a successful screenshot capture, **When** the file is saved, **Then** a desktop notification appears displaying an image preview thumbnail and action buttons.
2. **Given** the notification is displayed, **When** the user selects the "Open Folder" action, **Then** the file manager opens with the screenshot file highlighted or focused.
3. **Given** the notification is displayed, **When** the user selects the "Delete" action, **Then** the saved screenshot file is removed from disk and the notification is dismissed.
4. **Given** the notification is displayed, **When** the user ignores it, **Then** it automatically dismisses after a reasonable timeout while leaving the saved file and clipboard intact.

---

### User Story 3 - Interactive Image Annotation & Markup (Priority: P3)

As a workstation user, I want to mark up a capture with arrows, text, highlighting, rectangular outlines, numbering steps, and redaction (blur/pixelate), so that I can clearly communicate information or obscure sensitive data before sharing.

**Why this priority**: Essential for collaborating, bug reporting, and privacy protection (e.g., blurring credentials or tokens).

**Independent Test**: Trigger annotation mode (or click the annotate action on a capture notification), verify that the annotation tool opens with the captured image, apply annotations (e.g., blur and arrow), and confirm that the modified image can be copied to clipboard and/or saved.

**Acceptance Scenarios**:

1. **Given** a screenshot capture, **When** the annotation tool is launched, **Then** an interactive editor appears presenting drawing tools including arrow, rectangle, freehand line, text, highlight, redaction (blur/pixelation), and step counters.
2. **Given** an annotated image in the editor, **When** the user triggers copy, **Then** the updated annotated image replaces the clipboard content.
3. **Given** an annotated image in the editor, **When** the user triggers save, **Then** the updated image is written to disk.

---

### Edge Cases

- **Capture Cancellation**: If the user cancels the selection rectangle (e.g., presses Escape), the process must exit cleanly without generating empty files, corrupt clipboard data, or error notifications.
- **Multi-Monitor Display Configurations**: Area capture must correctly handle displays with different resolutions, scaling factors, or fractional scaling across multiple physical outputs without clipping or coordinate offsets.
- **Directory Auto-Creation**: If the designated screenshots directory (`~/Pictures/Screenshots`) does not exist at capture time, it must be automatically created without failing.
- **Notification Server Availability**: If the notification server is temporarily unresponsive, the core capture, clipboard copy, and file persistence must still succeed reliably.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide an interactive area capture mechanism allowing users to select any rectangular portion of the display.
- **FR-002**: The system MUST provide a full-screen capture mechanism that captures all visible display output.
- **FR-003**: Every successful capture MUST automatically save the image as a timestamped PNG file into a dedicated user screenshots directory (defaulting to `~/Pictures/Screenshots/`).
- **FR-004**: Every successful capture MUST automatically copy the image data to the system clipboard for immediate pasting.
- **FR-005**: Following capture, the system MUST emit a desktop notification presenting an image preview thumbnail and actionable buttons including opening the storage location, deleting the file, and launching the annotation editor.
- **FR-006**: The system MUST provide an annotation editor capable of drawing arrows, shapes, text annotations, numbered badges, highlights, crop boundaries, and privacy blurring/pixelation over captured images.
- **FR-007**: The screenshot workflow MUST follow a deferred notification-driven annotation model: every capture automatically saves the image to disk, copies the image data to the clipboard, and presents a thumbnail preview notification. The annotation editor (Satty) MUST only open when explicitly triggered via the "Annotate" action on the desktop notification.
- **FR-008**: The capture workflow MUST be integrated into the desktop environment using standard Linux PrintScreen keybindings: `Print` for interactive area/region capture, `Ctrl+Print` for full-screen capture, and `Alt+Print` for active window capture.
- **FR-009**: The screenshot workflow MUST handle cancellation gracefully without writing empty files or polluting clipboard history.

### Key Entities

- **Capture Request**: An invocation initiated by the user specifying the capture scope (interactive region, active output, or window).
- **Screenshot Artifact**: An image file saved to persistent user storage formatted with standardized timestamp naming.
- **Notification Thumbnail**: A transient desktop notification presenting the image preview and contextual action triggers.
- **Annotation Session**: An interactive canvas instance allowing graphical markup of the captured bitmap prior to final distribution.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A full-screen or region capture completes (saves to disk and populates clipboard) within 1.0 second of selection confirmation.
- **SC-002**: 100% of successful captures are simultaneously available in the system clipboard and persisted to the screenshots directory.
- **SC-003**: The desktop notification displaying the preview thumbnail appears within 500 milliseconds of capture completion.
- **SC-004**: Users can redact sensitive information (blur/pixelate) and copy the result in fewer than 3 clicks or keypresses once in the annotation editor.
- **SC-005**: Canceling a region selection generates 0 orphan files and triggers 0 error notifications.

## Assumptions

- The target platform is running a Wayland compositor (`niri`) with standard Wayland protocols for screencopy and layer shell.
- Notification daemon supports action buttons and image previews (via standard Freedesktop notification specification).
- The user's preferred screenshots directory is `~/Pictures/Screenshots/`.
