import AppKit
import Foundation

extension PromptComposerTextView {
	func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
		switch commandSelector {
		case #selector(NSResponder.insertNewline(_:)):
			commitVariableEditorChanges()
			return true
		case #selector(NSResponder.insertTab(_:)):
			return handleVariableEditorTabNavigation(forward: true)
		case #selector(NSResponder.insertBacktab(_:)):
			return handleVariableEditorTabNavigation(forward: false)
		case #selector(NSResponder.cancelOperation(_:)):
			cancelVariableEditor()
			window?.makeFirstResponder(self)
			return true
		default:
			return false
		}
	}

	func controlTextDidChange(_ obj: Notification) {
		if let active = activeVariableEditorContext {
			let previewToken = makeUpdatedVariableToken(
				from: active.token,
				editedValue: variableEditorField.stringValue
			)
			applyVariableTokenVisual(previewToken, in: active.range)
		}
		refreshVariableEditorLayoutIfNeeded()
	}

	func controlTextDidEndEditing(_ obj: Notification) {
		guard activeVariableEditorContext != nil else { return }
		commitVariableEditorChanges()
	}

	func handleVariableEditorTabNavigation(forward: Bool) -> Bool {
		guard config.variableTokenTabNavigationEnabled else {
			commitVariableEditorChanges()
			return true
		}
		guard let active = activeVariableEditorContext else {
			return focusAdjacentToken(from: selectedRange(), forward: forward)
		}

		let currentSelection = active.range
		commitVariableEditorChanges()
		return focusAdjacentToken(from: currentSelection, forward: forward)
	}
}
