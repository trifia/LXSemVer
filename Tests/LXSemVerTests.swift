//
//  LXSemVerTests.swift
//  LXSemVerTests
//
//  Created by Stan Chang Khin Boon on 21/10/15.
//  Copyright © 2015 lxcid. All rights reserved.
//

import XCTest
@testable import LXSemVer

// http://stackoverflow.com/a/24029847
extension Collection {
    /// Return a copy of `self` with its elements shuffled
    func shuffle() -> [Iterator.Element] {
        var list = Array(self)
        list.shuffleInPlace()
        return list
    }
}

extension MutableCollection where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffleInPlace() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }
        
        for i in 0..<count - 1 {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}

private func hasMatch(_ string: String, regex: NSRegularExpression) -> Bool {
    let numberOfMatches = regex.numberOfMatches(in: string, options: [], range: NSMakeRange(0, string.characters.count))
    return numberOfMatches > 0
}

class DotSeparatedValuesTests: XCTestCase {
    func testInstantiation() {
        XCTAssertNil(DotSeparatedValues(values: []))
        
        XCTAssertNil(DotSeparatedValues(string: ""))
        XCTAssertNil(DotSeparatedValues(string: "."))
        XCTAssertNil(DotSeparatedValues(string: "1..1"))
        XCTAssertNil(DotSeparatedValues(string: ".1"))
        XCTAssertNil(DotSeparatedValues(string: "🐮🐶.moof"))
        XCTAssertNil(DotSeparatedValues(string: "1.01"))
        XCTAssertNil(DotSeparatedValues(string: "\\"))
        
        XCTAssertEqual(DotSeparatedValues(unicodeScalarLiteral: "alpha"), DotSeparatedValues(values: ["alpha"]))
        XCTAssertEqual(DotSeparatedValues(extendedGraphemeClusterLiteral: "alpha.beta"), DotSeparatedValues(values: ["alpha", "beta"]))
        XCTAssertEqual(DotSeparatedValues(stringLiteral: "1.0.0"), DotSeparatedValues(values: ["1", "0", "0"]))
    }
    
    func testDescription() {
        XCTAssertEqual(DotSeparatedValues(stringLiteral: "0.0.0").description, "0.0.0")
    }
    
    func testComparable() {
        XCTAssert(DotSeparatedValues(stringLiteral: "1.0.0") < DotSeparatedValues(stringLiteral: "2.0.0"))
        XCTAssert(DotSeparatedValues(stringLiteral: "2.0.0") < DotSeparatedValues(stringLiteral: "2.1.0"))
        XCTAssert(DotSeparatedValues(stringLiteral: "2.1.0") < DotSeparatedValues(stringLiteral: "2.1.1"))
        
        XCTAssertFalse(DotSeparatedValues(stringLiteral: "1.0.0") > DotSeparatedValues(stringLiteral: "2.0.0"))
        XCTAssertFalse(DotSeparatedValues(stringLiteral: "2.0.0") > DotSeparatedValues(stringLiteral: "2.1.0"))
        XCTAssertFalse(DotSeparatedValues(stringLiteral: "2.1.0") > DotSeparatedValues(stringLiteral: "2.1.1"))
        
        XCTAssert(DotSeparatedValues(stringLiteral: "alpha") < DotSeparatedValues(stringLiteral: "alpha.1"))
        XCTAssert(DotSeparatedValues(stringLiteral: "alpha.1") < DotSeparatedValues(stringLiteral: "alpha.beta"))
        XCTAssert(DotSeparatedValues(stringLiteral: "alpha.beta") < DotSeparatedValues(stringLiteral: "beta"))
        XCTAssert(DotSeparatedValues(stringLiteral: "beta") < DotSeparatedValues(stringLiteral: "beta.2"))
        XCTAssert(DotSeparatedValues(stringLiteral: "beta.2") < DotSeparatedValues(stringLiteral: "beta.11"))
        XCTAssert(DotSeparatedValues(stringLiteral: "beta.11") < DotSeparatedValues(stringLiteral: "rc.1"))
        
        XCTAssertFalse(DotSeparatedValues(stringLiteral: "alpha") > DotSeparatedValues(stringLiteral: "alpha.1"))
        XCTAssertFalse(DotSeparatedValues(stringLiteral: "alpha.1") > DotSeparatedValues(stringLiteral: "alpha.beta"))
    }
    
    func testNext() {
        XCTAssertEqual(
            DotSeparatedValues(stringLiteral: "alpha").next(),
            [
                DotSeparatedValues(stringLiteral: "alpha.1")
            ]
        )
        
        XCTAssertEqual(
            DotSeparatedValues(stringLiteral: "alpha.1").next(),
            [
                DotSeparatedValues(stringLiteral: "alpha.2")
            ]
        )
        
        XCTAssertEqual(
            DotSeparatedValues(stringLiteral: "alpha.beta").next(),
            [
                DotSeparatedValues(stringLiteral: "alpha.1"),
                DotSeparatedValues(stringLiteral: "alpha.beta.1")
            ]
        )
        
        XCTAssertEqual(
            DotSeparatedValues(stringLiteral: "alpha.beta.1").next(),
            [
                DotSeparatedValues(stringLiteral: "alpha.1"),
                DotSeparatedValues(stringLiteral: "alpha.beta.2")
            ]
        )
    }
}

class VersionTests: XCTestCase {
    func testInstantiation() {
        XCTAssertNil(Version(string: "0.0.0-.alpha"))
        XCTAssertNil(Version(string: "0.0.0-beta.2+..."))
        
        XCTAssertNil(Version(string: "0.0.0-alpha..1"))
        XCTAssertNil(Version(string: "0.0.0-📱.1"))
        
        XCTAssertNil(Version(string: "0.0.0-"))
        XCTAssertNil(Version(string: "0.0.0+"))
        
        XCTAssertEqual(Version(unicodeScalarLiteral: "0.0.0"), Version(major: 0, minor: 0, patch: 0))
        XCTAssertEqual(Version(extendedGraphemeClusterLiteral: "0.0.0-alpha"), Version(major: 0, minor: 0, patch: 0, prerelease: [ "alpha" ]))
        XCTAssertEqual(Version(stringLiteral: "1.0.0-beta.2+exp.sha.5114f85"), Version(major: 1, minor: 0, patch: 0, prerelease: [ "beta", "2" ], buildMetadata: "exp.sha.5114f85"))
    }
    
    func testDescription() {
        XCTAssertEqual(Version(stringLiteral: "0.0.0").description, "0.0.0")
        XCTAssertEqual(Version(stringLiteral: "0.0.0-alpha").description, "0.0.0-alpha")
        XCTAssertEqual(Version(stringLiteral: "1.0.0-beta.2+exp.sha.5114f85").description, "1.0.0-beta.2+exp.sha.5114f85")
    }
    
    func testSemVer_2_0_0_Spec_2() {
        // Ensure Swift does not overflow when casting the string "-1" to an unsigned integer value.
        XCTAssertNil(UInt("-1"))
        XCTAssertEqual(UInt("0")!, 0)
        XCTAssertEqual(UInt("1")!, 1)
        
        XCTAssertNotNil(Version(string: "1.0.0"))
        XCTAssertNil(Version(string: "01.0.0"))
        XCTAssertNotNil(Version(string: "1.5.0"))
        XCTAssertNil(Version(string: "1.05.0"))
        XCTAssertNotNil(Version(string: "0.1.7"))
        XCTAssertNil(Version(string: "0.1.007"))
        
        XCTAssertNotNil(Version(string: "1.1.1"))
        XCTAssertNil(Version(string: "-1.1.1"))
        XCTAssertNil(Version(string: "1.-1.1"))
        XCTAssertNil(Version(string: "1.1.-1"))
    }
    
    func testSemVer_2_0_0_Spec_11() {
        do {
            XCTAssertLessThan(Version(stringLiteral: "1.0.0"), Version(stringLiteral: "2.0.0"))
            XCTAssertLessThan(Version(stringLiteral: "2.0.0"), Version(stringLiteral: "2.1.0"))
            XCTAssertLessThan(Version(stringLiteral: "2.1.0"), Version(stringLiteral: "2.1.1"))
            
            let versions: [Version] = [
                "1.0.0",
                "2.0.0",
                "2.1.0",
                "2.1.1",
            ]
            XCTAssertEqual(versions.shuffle().sorted(by: <), versions)
        }
        
        XCTAssert(Version(stringLiteral: "1.0.0-alpha") < Version(stringLiteral: "1.0.0"))
        
        do {
            XCTAssertLessThan(Version(stringLiteral: "1.0.0-alpha"), Version(stringLiteral: "1.0.0-alpha.1"))
            XCTAssertLessThan(Version(stringLiteral: "1.0.0-alpha.1"), Version(stringLiteral: "1.0.0-alpha.beta"))
            XCTAssertLessThan(Version(stringLiteral: "1.0.0-alpha.beta"), Version(stringLiteral: "1.0.0-beta"))
            XCTAssertLessThan(Version(stringLiteral: "1.0.0-beta"), Version(stringLiteral: "1.0.0-beta.2"))
            XCTAssertLessThan(Version(stringLiteral: "1.0.0-beta.2"), Version(stringLiteral: "1.0.0-beta.11"))
            XCTAssertLessThan(Version(stringLiteral: "1.0.0-beta.11"), Version(stringLiteral: "1.0.0-rc.1"))
            XCTAssertLessThan(Version(stringLiteral: "1.0.0-rc.1"), Version(stringLiteral: "1.0.0"))
            
            let versions: [Version] = [
                "1.0.0-alpha",
                "1.0.0-alpha.1",
                "1.0.0-alpha.beta",
                "1.0.0-beta",
                "1.0.0-beta.2",
                "1.0.0-beta.11",
                "1.0.0-rc.1",
                "1.0.0",
            ]
            XCTAssertEqual(versions.shuffle().sorted(by: <), versions)
        }
    }
    
    func testVersionNext() {
        XCTAssertEqual(
            Version(major: 1, minor: 0, patch: 0).next(),
            [
                Version(major: 1, minor: 0, patch: 1, prerelease: "alpha.1"),
                Version(major: 1, minor: 1, patch: 0, prerelease: "alpha.1"),
                Version(major: 2, minor: 0, patch: 0, prerelease: "alpha.1")
            ]
        )
        
        XCTAssertEqual(
            Version(major: 1, minor: 0, patch: 0, prerelease: "alpha").next(),
            [
                Version(major: 1, minor: 0, patch: 0, prerelease: "alpha.1"),
                Version(major: 1, minor: 0, patch: 0, prerelease: "beta.1")
            ]
        )
        
        XCTAssertEqual(
            Version(major: 1, minor: 0, patch: 0, prerelease: "alpha.1").next(),
            [
                Version(major: 1, minor: 0, patch: 0, prerelease: "alpha.2"),
                Version(major: 1, minor: 0, patch: 0, prerelease: "beta.1")
            ]
        )
        
        XCTAssertEqual(
            Version(major: 1, minor: 0, patch: 0, prerelease: "beta.9").next(),
            [
                Version(major: 1, minor: 0, patch: 0, prerelease: "beta.10"),
                Version(major: 1, minor: 0, patch: 0, prerelease: "rc.1")
            ]
        )
        
        XCTAssertEqual(
            Version(major: 1, minor: 0, patch: 0, prerelease: "rc.3").next(),
            [
                Version(major: 1, minor: 0, patch: 0, prerelease: "rc.4"),
                Version(major: 1, minor: 0, patch: 0)
            ]
        )
        
        XCTAssertEqual(
            Version(stringLiteral: "1.0.0-nightly.1").next(),
            [
                Version(stringLiteral: "1.0.0-nightly.2")
            ]
        )
    }
}
