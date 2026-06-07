import Foundation

public class XMLNode: Codable {
	public init(_ name: String, namespace: String? = nil, qName: String? = nil, attributes: [String : String] = [:], children: [XMLNode] = []) {
		self.children = children
		self.name = name
		self.namespace = namespace
		self.qName = qName
		self.attributes = attributes
		self.path = "/"
	}
	
	public func find(_ key: String) -> [XMLNode] {
		if keyMatch(key) { return [self] }
		var ret: [XMLNode] = []
		children.forEach { child in
			ret.append(contentsOf: child.find(key))
		}
		return ret
	}
	
	private func keyMatch(_ key: String) -> Bool {
		if key.contains(":") {
			let items = key.split(separator: ":").map {String($0).trimmingCharacters(in: .whitespacesAndNewlines)}
			if let namespace, namespace.localizedCaseInsensitiveCompare(items.first!) == .orderedSame {
				if name.localizedCaseInsensitiveCompare(items[1]) == .orderedSame {
					return true
				}
			} else {
				return name.localizedCaseInsensitiveCompare(items[1]) == .orderedSame
			}
		}
		return name.localizedCaseInsensitiveCompare(key) == .orderedSame
	}
	
	public subscript(address: String) -> [XMLNode] {
		get {
			let split = address.split(separator: "/", omittingEmptySubsequences: false).map {String($0)}
			return self[split]
		}
	}
	
	public subscript(address: [String]) -> [XMLNode] {
		get {
			guard address.count > 0 else { return [] }
			var ret: [XMLNode] = []
			var node: XMLNode? = self
			var address = address

			if address.first!.isEmpty {
				address.removeFirst()
			}
			while address.count > 0 && node != nil {
				if address.count == 1 {
					ret.append(contentsOf: node!.children.filter {$0.keyMatch(address.first!)})
					address = []
				} else {
					node = node?.children.first(where: {$0.keyMatch(address.first!)})
					address.removeFirst()
				}
			}

			return ret
		}
	}
	
	public var children: [XMLNode] = []
	public var name: String
	public var namespace: String?
	public var qName: String?
	public var attributes: [String:String]
	public var text: String?
	public private(set) var path: String
	
	public func attr<T>(_ key: String, _ defaultValue: T) -> T {
		guard attributes.keys.contains(key) else { return defaultValue }
		return (attributes[key] as? T) ?? defaultValue
	}
	
	internal func setPath(_ pathName: String) {
		if pathName.hasSuffix("/") {
			path = pathName + getKey()
		} else {
			path = "\(pathName)/\(getKey())"
		}
		children.forEach {$0.setPath(path)}
	}
		
	private func getKey() -> String {
		if let namespace {
			return "\(namespace):\(name)"
		}
		return name
	}
}


public class XMLNodeTree: Codable {
	public var topNode: XMLNode? {
		didSet {
			topNode?.setPath("/")
		}
	}
	
	public subscript(key: String) -> [XMLNode] {
		get {
			return topNode?[key] ?? []
		}
	}
	
	public init(topNode: XMLNode? = nil) {
		self.topNode = topNode
		topNode?.setPath("/")
	}
}

class XMLTreeParser: XMLParser {
	init(url: URL) {
		if let data = try? Data(contentsOf: url) {
			super.init(data: data)
			self.delegate = self
		} else {
			super.init()
		}
	}
	override init(data: Data) {
		super.init(data: data)
		self.delegate = self
	}
	
	var nodes: [XMLNode] = [XMLNode("")]
		
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		let node = XMLNode(elementName, namespace: namespaceURI, qName: qName, attributes: attributeDict, children: [])
		if let parent = nodes.last {
			parent.children.append(node)
			nodes.append(node)
		}
		else {
			nodes.append(node)
		}
	}
	
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		if let _ = nodes.last {
			nodes.removeLast()
		}
	}
	
	func parser(_ parser: XMLParser, foundCharacters string: String) {
		nodes.last?.text = string
	}
	
	func parserDidEndDocument(_ parser: XMLParser) {
	}
	
	static func parse(url: URL) -> XMLNodeTree {
		let instance = XMLTreeParser(url: url)
		return XMLNodeTree(topNode: instance.nodes.first)
	}
}

extension XMLTreeParser: XMLParserDelegate {}
