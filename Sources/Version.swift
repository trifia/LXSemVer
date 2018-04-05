// Version.swift
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

func versionComponentFromCharacters(_ characters: Substring) -> UInt? {
    let charactersCount = characters.count
    guard charactersCount > 0, let firstCharacter = characters.first, firstCharacter != "0" else {
        return nil
    }
    return UInt(String(characters))
}

public struct Version {
    public let major: UInt
    public let minor: UInt
    public let patch: UInt
    public let prerelease: DotSeparatedValues?
    public let buildMetadata: DotSeparatedValues?

    public init(major: UInt, minor: UInt, patch: UInt, prerelease: DotSeparatedValues? = nil, buildMetadata: DotSeparatedValues? = nil) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
        self.buildMetadata = buildMetadata
    }

    // Heavily referenced from Swift Package Manager to build a non regex version
    public init?(string: String) {
        let prereleaseStartIndex = string.index(of: "-")
        let buildMetadataStartIndex = string.index(of: "+")

        let versionEndIndex = prereleaseStartIndex ?? buildMetadataStartIndex ?? string.endIndex
        let versionCharacters = string.prefix(upTo: versionEndIndex)
        var versionComponents = versionCharacters.split(separator: ".", maxSplits: 2, omittingEmptySubsequences: false).compactMap(versionComponentFromCharacters)

        guard versionComponents.count == 3 else {
            return nil
        }

        var prerelease: DotSeparatedValues?
        if let prereleaseStartIndex = prereleaseStartIndex {
            let prereleaseEndIndex = buildMetadataStartIndex ?? string.endIndex
            let prereleaseCharacters = string[string.index(after: prereleaseStartIndex)..<prereleaseEndIndex]
            prerelease = DotSeparatedValues(string: String(prereleaseCharacters))
            if prerelease == nil {
                return nil
            }
        }

        var buildMetadata: DotSeparatedValues?
        if let buildMetadataStartIndex = buildMetadataStartIndex {
            let buildMetadataCharacters = string.suffix(from: string.index(after: buildMetadataStartIndex))
            buildMetadata = DotSeparatedValues(string: String(buildMetadataCharacters))
            if buildMetadata == nil {
                return nil
            }
        }

        self.init(major: versionComponents[0], minor: versionComponents[1], patch: versionComponents[2], prerelease: prerelease, buildMetadata: buildMetadata)
    }
}

extension Version : Equatable {
}

public func ==(lhs: Version, rhs: Version) -> Bool {
    return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch && lhs.prerelease == rhs.prerelease
}

extension Version : Comparable {
}

public func <(lhs: Version, rhs: Version) -> Bool {
    if lhs.major != rhs.major {
        return lhs.major < rhs.major
    } else if lhs.minor != rhs.minor {
        return lhs.minor < rhs.minor
    } else if lhs.patch != rhs.patch {
        return lhs.patch < rhs.patch
    } else if let lprv = lhs.prerelease, let rprv = rhs.prerelease, lprv != rprv {
        return lprv < rprv
    } else if lhs.prerelease != nil && rhs.prerelease == nil {
        return true
    } else {
        return false
    }
}

extension Version : ExpressibleByStringLiteral {
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

extension Version : CustomStringConvertible {
    public var description: String {
        var description = "\(self.major).\(self.minor).\(self.patch)"
        if let prerelease = self.prerelease {
            description += "-\(prerelease)"
        }
        if let buildMetadata = self.buildMetadata {
            description += "+\(buildMetadata)"
        }
        return description
    }
}

extension Version {
    public func next() -> [Version] {
        if let prerelease = self.prerelease {
            var versions = prerelease.next().map { Version(major: self.major, minor: self.minor, patch: self.patch, prerelease: $0) }
            if let firstPrereleaseIdentifier = prerelease.values.first?.lowercased() {
                switch firstPrereleaseIdentifier {
                case "alpha":
                    versions.append(Version(major: self.major, minor: self.minor, patch: self.patch, prerelease: "beta.1"))
                case "beta":
                    versions.append(Version(major: self.major, minor: self.minor, patch: self.patch, prerelease: "rc.1"))
                case "rc":
                    versions.append(Version(major: self.major, minor: self.minor, patch: self.patch))
                    break
                default:
                    break
                }
            }
            return versions
        } else {
            return [
                Version(major: self.major, minor: self.minor, patch: self.patch + 1, prerelease: "alpha.1"),
                Version(major: self.major, minor: self.minor + 1, patch: 0, prerelease: "alpha.1"),
                Version(major: self.major + 1, minor: 0, patch: 0, prerelease: "alpha.1")
            ]
        }
    }
}
