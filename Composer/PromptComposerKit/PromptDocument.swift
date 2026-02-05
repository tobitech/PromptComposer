import Foundation

public struct PromptDocument: Equatable, Codable {
	public var segments: [Segment]

	public init(segments: [Segment] = []) {
		self.segments = segments
	}
}

public enum Segment: Equatable, Codable {
	case text(String)
	case token(Token)

	private enum CodingKeys: String, CodingKey {
		case type
		case text
		case token
	}

	private enum SegmentType: String, Codable {
		case text
		case token
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(SegmentType.self, forKey: .type)
		switch type {
		case .text:
			let value = try container.decode(String.self, forKey: .text)
			self = .text(value)
		case .token:
			let value = try container.decode(Token.self, forKey: .token)
			self = .token(value)
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case .text(let value):
			try container.encode(SegmentType.text, forKey: .type)
			try container.encode(value, forKey: .text)
		case .token(let value):
			try container.encode(SegmentType.token, forKey: .type)
			try container.encode(value, forKey: .token)
		}
	}
}

public struct Token: Equatable, Codable, Identifiable {
	public var id: UUID
	public var kind: TokenKind
	public var display: String
	public var metadata: [String: String]

	public init(
		id: UUID = UUID(),
		kind: TokenKind,
		display: String,
		metadata: [String: String] = [:]
	) {
		self.id = id
		self.kind = kind
		self.display = display
		self.metadata = metadata
	}
}

public enum TokenKind: String, Codable {
	case variable
	case fileMention
	case command
}
