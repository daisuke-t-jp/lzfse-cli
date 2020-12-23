import XCTest

import lzfse_cliTests

var tests = [XCTestCaseEntry]()
tests += lzfse_cliTests.allTests()
XCTMain(tests)
