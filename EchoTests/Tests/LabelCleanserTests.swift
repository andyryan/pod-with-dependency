//
//  LabelCleanserTests.swift
//  EchoTests
//
//  Created by Andrew Ryan on 21/11/2018.
//  Copyright © 2018 BBC. All rights reserved.
//

import XCTest

class LabelCleanserTests: XCTestCase {

    func testCleanseCustomLabelStipsSquareBrackets() {
        let dirtyLabel = "[square]"
        let cleanLabel = LabelCleanser.cleanCustomVariable(dirtyLabel)
        XCTAssertEqual(cleanLabel, "square")
    }

    func testCleanseCustomLabelTrimsWhitespace() {
        let dirtyLabel = "   spacey   "
        let cleanLabel = LabelCleanser.cleanCustomVariable(dirtyLabel)
        XCTAssertEqual(cleanLabel, "spacey")
    }

    func testCleanseCustomLabelReplacesConsecutiveWhiteSpace() {
        let dirtyLabel = "white    space"
        let cleanLabel = LabelCleanser.cleanCustomVariable(dirtyLabel)
        XCTAssertEqual(cleanLabel, "white space")
    }

    func testCleanseCustomLabelReplacesAmp() {
        let dirtyLabel = "amp&res&ands"
        let cleanLabel = LabelCleanser.cleanCustomVariable(dirtyLabel)
        XCTAssertEqual(cleanLabel, "amp$res$ands")
    }

}
