import Foundation

extension Data {
	func hexEncodedString() -> String {
		return map { String(format: "%02hhx", $0) }.joined(separator: " ")
	}
}

extension Bool {
	var icon: String { return self ? "⬛️" : "⬜️" }
}
