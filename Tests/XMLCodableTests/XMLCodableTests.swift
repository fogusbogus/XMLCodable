import Testing
import Foundation
@testable import XMLCodable

@Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    // Swift Testing Documentation
    // https://developer.apple.com/documentation/testing
	let xml = "<?xml version=\"1.0\"?><someTag someAttr anotherAttr=\"Some data\" />"
	let url = URL(filePath: "/Users/matt/Movies/RHPS Subtitles ITT Format_iTT_English (United States).itt")!
	let parser = ITunesTimedTextParser(contentsOf: url)! //MemoParser(data: xml.data(using: .utf8)!)
	parser.parse()
	if let error = parser.parserError {
		print(error)
	}
	let jsonS = JSONEncoder()
	print(try String(data: jsonS.encode(parser.nodes.first!), encoding: .utf8)!)
	try String(data: jsonS.encode(parser.nodes.first!), encoding: .utf8)?.write(toFile: "/Users/matt/ittSample.json", atomically: true, encoding: .utf8)
}



