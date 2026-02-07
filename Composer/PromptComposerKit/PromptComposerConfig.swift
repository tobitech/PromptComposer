import AppKit
import Foundation

public struct PromptCommand: Identifiable {
	public enum Mode {
		case insertToken
		case runCommand
	}

	public var id: UUID

	/// Command keyword matched after `/`, for example "summarize".
	public var keyword: String

	/// Display title shown in the suggestion list.
	public var title: String
	public var subtitle: String?
	public var section: String?
	public var symbolName: String?

	/// Determines whether selection inserts a token or runs immediately.
	public var mode: Mode

	/// Optional override for inserted token text (insert-token mode only).
	public var tokenDisplay: String?

	/// Extra metadata added to inserted command tokens.
	public var metadata: [String: String]

	public init(
		id: UUID = UUID(),
		keyword: String,
		title: String,
		subtitle: String? = nil,
		section: String? = nil,
		symbolName: String? = nil,
		mode: Mode,
		tokenDisplay: String? = nil,
		metadata: [String: String] = [:]
	) {
		self.id = id
		self.keyword = keyword
		self.title = title
		self.subtitle = subtitle
		self.section = section
		self.symbolName = symbolName
		self.mode = mode
		self.tokenDisplay = tokenDisplay
		self.metadata = metadata
	}
}

public struct PromptComposerConfig {
	public enum GrowthDirection {
		case down
		case up
	}

	public var isEditable: Bool = true
	public var isSelectable: Bool = true
	
	public var font: NSFont = .systemFont(ofSize: NSFont.systemFontSize)
	public var textColor: NSColor = .labelColor
	
	public var backgroundColor: NSColor = .clear

	/// Border styling for the editor container.
	public var showsBorder: Bool = true
	public var borderColor: NSColor = .separatorColor
	public var borderWidth: CGFloat = 1
	public var cornerRadius: CGFloat = 8
	
	/// Padding inside text container (horizontal/vertical).
	public var textInsets: NSSize = .init(width: 12, height: 10)
	
	/// Scroll behaviour
	public var hasVerticalScroller: Bool = true
	public var hasHorizontalScroller: Bool = false
	
	public var isRichText: Bool = true
	
	public var allowsUndo: Bool = true

	/// Auto-sizing behaviour
	public var minVisibleLines: Int = 1
	public var maxVisibleLines: Int = 15
	public var growthDirection: GrowthDirection = .down
	
	/// Called for Return/Enter when `submitsOnEnter` is enabled.
	public var onSubmit: (() -> Void)? = nil
	
	public var submitsOnEnter: Bool = false

	/// Suggestion provider for the popover shell (Step 6).
	public var suggestionsProvider: ((PromptSuggestionContext) -> [PromptSuggestion])? = nil

	/// File mention suggestions for active `@` queries (Step 7).
	/// The closure receives the query text without `@`.
	public var suggestFiles: ((String) -> [PromptSuggestion])? = nil

	/// Slash-command definitions used when `/` is active (Step 8).
	public var commands: [PromptCommand] = []

	/// Enables Tab / Shift-Tab navigation across variable tokens.
	public var variableTokenTabNavigationEnabled: Bool = true

	/// Focuses the first variable token when the editor first appears.
	public var autoFocusFirstVariableTokenOnAppear: Bool = false

	/// Called when a suggestion is selected.
	public var onSuggestionSelected: ((PromptSuggestion) -> Void)? = nil

	/// Called when a run-command slash command is selected.
	public var onCommandExecuted: ((PromptCommand) -> Void)? = nil

	/// Suggestion panel sizing for non-compact lists (for example slash commands).
	public var suggestionPanelWidth: CGFloat = 360
	public var suggestionPanelMaxHeight: CGFloat = 360

	/// Suggestion panel sizing for compact lists (for example @ mentions).
	public var compactSuggestionPanelWidth: CGFloat = 328
	public var compactSuggestionPanelMaxHeight: CGFloat = 300
	
	public init() {}
}
