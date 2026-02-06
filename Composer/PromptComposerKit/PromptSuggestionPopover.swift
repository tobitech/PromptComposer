import AppKit
import Combine
import SwiftUI

final class PromptSuggestionViewModel: ObservableObject {
	@Published var items: [PromptSuggestion] = []
	@Published var selectedIndex: Int = 0

	var selectedItem: PromptSuggestion? {
		guard items.indices.contains(selectedIndex) else { return nil }
		return items[selectedIndex]
	}

	func updateItems(_ newItems: [PromptSuggestion]) {
		items = newItems
		if items.isEmpty {
			selectedIndex = 0
		} else if selectedIndex >= items.count {
			selectedIndex = max(0, items.count - 1)
		}
	}

	func moveSelection(by delta: Int) {
		guard !items.isEmpty else { return }
		let nextIndex = min(max(selectedIndex + delta, 0), items.count - 1)
		selectedIndex = nextIndex
	}

	var groupedItems: [PromptSuggestionSection] {
		var sections: [PromptSuggestionSection] = []
		var currentTitle: String?
		var currentRows: [PromptSuggestionIndexedItem] = []

		for (index, item) in items.enumerated() {
			let normalizedTitle = item.section?.uppercased()
			if normalizedTitle != currentTitle {
				if !currentRows.isEmpty {
					sections.append(PromptSuggestionSection(title: currentTitle, rows: currentRows))
					currentRows = []
				}
				currentTitle = normalizedTitle
			}
			currentRows.append(PromptSuggestionIndexedItem(index: index, item: item))
		}

		if !currentRows.isEmpty {
			sections.append(PromptSuggestionSection(title: currentTitle, rows: currentRows))
		}

		return sections
	}
}

struct PromptSuggestionIndexedItem: Identifiable {
	let index: Int
	let item: PromptSuggestion

	var id: Int { index }
}

struct PromptSuggestionSection: Identifiable {
	let id = UUID()
	let title: String?
	let rows: [PromptSuggestionIndexedItem]
}

struct PromptSuggestionListView: View {
	@ObservedObject var model: PromptSuggestionViewModel
	let onSelect: (PromptSuggestion) -> Void

	var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			ForEach(model.groupedItems) { section in
				VStack(alignment: .leading, spacing: 6) {
					if let title = section.title, !title.isEmpty {
						Text(title)
							.font(.system(size: 12, weight: .semibold))
							.foregroundColor(Color(NSColor.tertiaryLabelColor))
					}

					VStack(spacing: 0) {
						ForEach(section.rows) { indexed in
							PromptSuggestionRow(
								item: indexed.item,
								isSelected: indexed.index == model.selectedIndex
							)
							.onTapGesture {
								model.selectedIndex = indexed.index
								onSelect(indexed.item)
							}

							if indexed.id != section.rows.last?.id {
								Divider()
									.overlay(Color(NSColor.separatorColor).opacity(0.5))
							}
						}
					}
				}
			}
		}
		.padding(12)
		.frame(width: 360)
		.fixedSize(horizontal: false, vertical: true)
		.background(
			RoundedRectangle(cornerRadius: 14, style: .continuous)
				.fill(Color(NSColor.windowBackgroundColor))
		)
			.overlay(
				RoundedRectangle(cornerRadius: 14, style: .continuous)
					.stroke(Color(NSColor.separatorColor).opacity(0.75), lineWidth: 1)
			)
		.shadow(color: Color.black.opacity(0.13), radius: 16, x: 0, y: 6)
	}
}

struct PromptSuggestionRow: View {
	let item: PromptSuggestion
	let isSelected: Bool

	private var iconName: String {
		if let symbolName = item.symbolName {
			return symbolName
		}
		guard let kind = item.kind else { return "sparkle.magnifyingglass" }
		switch kind {
		case .variable:
			return "text.cursor"
		case .fileMention:
			return "doc"
		case .command:
			return "bolt"
		}
	}

	var body: some View {
		HStack(alignment: .top, spacing: 10) {
			Image(systemName: iconName)
				.font(.system(size: 15, weight: .semibold))
				.frame(width: 32, height: 32)
				.background(
					Circle()
						.fill(isSelected ? Color.white.opacity(0.22) : Color(NSColor.controlBackgroundColor))
				)
				.foregroundColor(isSelected ? Color.white : Color(NSColor.labelColor))

			VStack(alignment: .leading, spacing: 2) {
				Text(item.title)
					.font(.system(size: 17, weight: .semibold))
					.foregroundColor(isSelected ? Color.white : Color(NSColor.labelColor))
				if let subtitle = item.subtitle {
					Text(subtitle)
						.font(.system(size: 14, weight: .medium))
						.foregroundColor(
							isSelected
								? Color.white.opacity(0.92)
								: Color(NSColor.secondaryLabelColor)
						)
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}
		.padding(.horizontal, 8)
		.padding(.vertical, 7)
		.background(
			RoundedRectangle(cornerRadius: 8, style: .continuous)
				.fill(isSelected ? Color(NSColor.controlAccentColor) : Color.clear)
		)
		.contentShape(Rectangle())
	}
}

final class PromptSuggestionPanelController: NSObject {
	private final class FloatingPanel: NSPanel {
		override var canBecomeKey: Bool { false }
		override var canBecomeMain: Bool { false }
	}

	private let panel: FloatingPanel
	private let viewModel = PromptSuggestionViewModel()
	private let hostingView: NSHostingView<PromptSuggestionListView>
	private var anchorRange: NSRange?

	weak var textView: PromptComposerTextView?

	override init() {
		hostingView = NSHostingView(
			rootView: PromptSuggestionListView(
				model: PromptSuggestionViewModel(),
				onSelect: { _ in }
			)
		)
		panel = FloatingPanel(
			contentRect: NSRect(x: 0, y: 0, width: 360, height: 220),
			styleMask: [.borderless, .nonactivatingPanel],
			backing: .buffered,
			defer: true
		)
		super.init()

		hostingView.rootView = PromptSuggestionListView(
			model: viewModel,
			onSelect: { [weak self] item in
				self?.select(item)
			}
		)
		panel.contentView = hostingView
		panel.isOpaque = false
		panel.backgroundColor = .clear
		panel.hasShadow = true
		panel.level = .floating
		panel.isFloatingPanel = true
		panel.hidesOnDeactivate = false
		panel.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
	}

	var isVisible: Bool {
		panel.isVisible
	}

	func update(items: [PromptSuggestion], anchorRange: NSRange?) {
		viewModel.updateItems(items)
		self.anchorRange = anchorRange

		guard !items.isEmpty else {
			close()
			return
		}

		showOrUpdate()
	}

	func updateAnchor(anchorRange: NSRange? = nil) {
		if let anchorRange {
			self.anchorRange = anchorRange
		}
		guard panel.isVisible else { return }
		positionPanel()
	}

	func handleKeyDown(_ event: NSEvent) -> Bool {
		guard panel.isVisible else { return false }

		switch event.keyCode {
		case 125: // Down arrow
			viewModel.moveSelection(by: 1)
			return true
		case 126: // Up arrow
			viewModel.moveSelection(by: -1)
			return true
		case 36, 76: // Return / Numpad Enter
			if let selected = viewModel.selectedItem {
				select(selected)
			} else {
				close()
			}
			return true
		case 53: // Escape
			close()
			return true
		default:
			return false
		}
	}

	func dismiss() {
		close()
	}

	private func showOrUpdate() {
		guard textView != nil else { return }
		positionPanel()
		if !panel.isVisible {
			panel.orderFront(nil)
		}
	}

	private func select(_ item: PromptSuggestion) {
		let onSuggestionSelected = textView?.config.onSuggestionSelected
		close()
		DispatchQueue.main.async {
			onSuggestionSelected?(item)
		}
	}

	private func close() {
		panel.orderOut(nil)
	}

	private func positionPanel() {
		guard
			let textView,
			let anchorRect = textView.suggestionAnchorScreenRect(for: anchorRange)
		else {
			return
		}

		let fittingSize = hostingView.fittingSize
		let panelWidth = max(300, min(420, fittingSize.width))
		let panelHeight = max(80, min(420, fittingSize.height))

		let spacing: CGFloat = 8
		var originX = anchorRect.minX
		var originY = anchorRect.maxY + spacing

		if let screen = textView.window?.screen ?? NSScreen.main {
			let safeFrame = screen.visibleFrame.insetBy(dx: 8, dy: 8)

			if originX + panelWidth > safeFrame.maxX {
				originX = safeFrame.maxX - panelWidth
			}
			if originX < safeFrame.minX {
				originX = safeFrame.minX
			}

			if originY + panelHeight > safeFrame.maxY {
				originY = anchorRect.minY - panelHeight - spacing
			}
			if originY < safeFrame.minY {
				originY = safeFrame.minY
			}
		}

		let frame = NSRect(x: originX, y: originY, width: panelWidth, height: panelHeight)
		panel.setFrame(frame, display: panel.isVisible)
	}
}
