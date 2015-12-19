// DotSeparatedValues.swift
//
// Copyright (c) 2015 Trifia (http://trifia.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

func isValidValue(characters: String.CharacterView) -> Bool {
    if characters.isEmpty {
        return false
    }
    for character in characters {
        if character > Character(UnicodeScalar(127)) {
            return false
        }
    }
    return true
}

public struct DotSeparatedValues {
    public let values: [String]
    
    public init?(characters: String.CharacterView) {
        let values = characters.split(".", maxSplit: Int.max, allowEmptySlices: true)
        assert(!values.isEmpty)
        for value in values {
            if !isValidValue(value) {
                return nil
            }
        }
        self.init(values: values.map(String.init))
    }
    
    public init?(string: String) {
        self.init(characters: string.characters)
    }
    
    public init?(values: [String]) {
        guard !values.isEmpty else {
            return nil
        }
        self.values = values
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
