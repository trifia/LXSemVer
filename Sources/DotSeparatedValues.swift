public struct DotSeparatedValues {
    public let values: [String]
    
    public init?(values: [String]) {
        guard !values.isEmpty else {
            return nil
        }
        self.values = values
    }
    
    public init?(string: String) {
        let values = string.characters.split(".", maxSplit: Int.max, allowEmptySlices: true)
        assert(!values.isEmpty)
        for value in values {
            if value.isEmpty {
                return nil
            }
        }
        self.init(values: values.map(String.init))
    }
}

extension DotSeparatedValues : Equatable {
}

public func ==(lhs: DotSeparatedValues, rhs: DotSeparatedValues) -> Bool {
    return lhs.values == rhs.values
}

extension DotSeparatedValues : Comparable {
}

public func <(lhs: DotSeparatedValues, rhs: DotSeparatedValues) -> Bool {
    for (lvalue, rvalue) in zip(lhs.values, rhs.values) {
        if lvalue == rvalue {
            continue
        }
        let lnumOpt = Int(lvalue)
        let rnumOpt = Int(rvalue)
        if let lnum = lnumOpt, let rnum = rnumOpt where lnum < rnum {
            return true
        } else if lnumOpt == nil && rnumOpt == nil && lvalue < rvalue {
            return true
        } else if lnumOpt != nil && rnumOpt == nil {
            return true
        } else {
            return false
        }
    }
    return lhs.values.count < rhs.values.count
}

extension DotSeparatedValues : ArrayLiteralConvertible {
    public init(arrayLiteral elements: String...) {
        self.init(values: elements)!
    }
}

extension DotSeparatedValues : StringLiteralConvertible {
    public init(unicodeScalarLiteral value: String) {
        self.init(string: value)!
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(string: value)!
    }
    
    public init(stringLiteral value: String) {
        self.init(string: value)!
    }
}

extension DotSeparatedValues : CustomStringConvertible {
    public var description: String {
        return self.values.joinWithSeparator(".")
    }
}

extension DotSeparatedValues {
    public func next() -> [DotSeparatedValues] {
        var result = [DotSeparatedValues]()
        for (index, value) in self.values.enumerate() {
            if let num = Int(value) {
                var valueSlice = self.values[0...index]
                valueSlice[index] = String(num + 1)
                result.append(DotSeparatedValues(values: Array(valueSlice))!)
                continue
            }
            
            let nextIndex = index + 1
            if nextIndex < self.values.count && Int(self.values[nextIndex]) != nil {
                continue
            }
            
            var newValues = Array(self.values[0...index])
            newValues.append("1")
            result.append(DotSeparatedValues(values: newValues)!)
        }
        return result
    }
}
