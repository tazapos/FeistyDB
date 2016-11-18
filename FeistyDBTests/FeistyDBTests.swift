//
// Copyright (c) 2015 - 2016 Feisty Dog, LLC
//
// See https://github.com/feistydog/FeistyDB/blob/master/LICENSE.txt for license information
//

import XCTest
@testable import FeistyDB

class FeistyDBTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
	func testDatabase() {
		let db = try! Database()

		try! db.execute(sql: "create table t1(a, b);")

		let rowCount = 10

		for _ in 0..<rowCount {
			try! db.execute(sql: "insert into t1 default values;")
		}

		let count: Int = try! db.prepare(sql: "select count(*) from t1;").front()

		XCTAssertEqual(count, rowCount)
	}

	func testInsert() {
		let db = try! Database()

		try! db.execute(sql: "create table t1(a text);")

		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: 1)
		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: "feisty")
		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: 2.5)
		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: Data(count: 8))

		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: URL(fileURLWithPath: "/tmp"))
		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: UUID())
		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: Date())

		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: NSNull())
	}

	func testIteration() {
		let db = try! Database()

		try! db.execute(sql: "create table t1(a);")

		let rowCount = 10

		for i in 0..<rowCount {
			try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: i)
		}

		let s = try! db.prepare(sql: "select * from t1;")
		var count = 0

		for row in s {
			for _ in row {
				XCTAssert(try! row.leftmostValue() as Int == count)
			}
			count += 1
		}

		XCTAssertEqual(count, rowCount)
	}

	func testUUIDExtension() {
		let db = try! Database()

		try! db.execute(sql: "create table t1(u text default (uuid4()));")
		try! db.execute(sql: "insert into t1 default values;")

		let u: UUID? = try! db.prepare(sql: "select * from t1 limit 1;").front()

		XCTAssertNotNil(u)
	}

	func testCustomCollation() {
		let db = try! Database()

		try! db.add(collation: "reversed", { (a, b) -> ComparisonResult in
			return b.compare(a)
		})

		try! db.execute(sql: "create table t1(a text);")

		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: "a")
		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: "c")
		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: "z")
		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: "e")

		var str = ""
		let s = try! db.prepare(sql: "select * from t1 order by a collate reversed;")
		try! s.execute { row in
			let c: String = try row.value(at: 0)
			str.append(c)
		}

		XCTAssertEqual(str, "zeca")
	}

	func testCustomFunction() {
		let db = try! Database()

		let rot13key: [Character: Character] = [
			"A": "N", "B": "O", "C": "P", "D": "Q", "E": "R", "F": "S", "G": "T", "H": "U", "I": "V", "J": "W", "K": "X", "L": "Y", "M": "Z",
			"N": "A", "O": "B", "P": "C", "Q": "D", "R": "E", "S": "F", "T": "G", "U": "H", "V": "I", "W": "J", "X": "K", "Y": "L", "Z": "M",
			"a": "n", "b": "o", "c": "p", "d": "q", "e": "r", "f": "s", "g": "t", "h": "u", "i": "v", "j": "w", "k": "x", "l": "y", "m": "z",
			"n": "a", "o": "b", "p": "c", "q": "d", "r": "e", "s": "f", "t": "g", "u": "h", "v": "i", "w": "j", "x": "k", "y": "l", "z": "m"]

		func rot13(_ s: String) -> String {
			return String(s.characters.map { rot13key[$0] ?? $0 })
		}

		try! db.add(function: "rot13", arity: 1) { values in
			let value = values.first.unsafelyUnwrapped
			switch value {
			case .text(let s):
				return .text(rot13(s))
			default:
				return value
			}
		}

		try! db.execute(sql: "create table t1(a);")

		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: "this")
		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: "is")
		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: "only")
		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: "a")
		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: "test")

		let s = try! db.prepare(sql: "select rot13(a) from t1;")
		let results = s.map { try! $0.leftmostValue() as String }

		XCTAssertEqual(results, ["guvf", "vf", "bayl", "n", "grfg"])

		try! db.remove(function: "rot13", arity: 1)
		XCTAssertThrowsError(try db.prepare(sql: "select rot13(a) from t1;"))
	}

	func testDatabaseBindings() {
		let db = try! Database()

		try! db.execute(sql: "create table t1(a, b);")

		for i in 0..<10 {
			try! db.execute(sql: "insert into t1(a, b) values (?, ?);", parameterValues: i, nil)
		}

		let statement = try! db.prepare(sql: "select * from t1 where a = ?")
		try! statement.bind(value: 5, toParameter: 1)

		try! statement.execute { row in
			let x: Int = try row.value(at: 0)
			let y: Int? = try row.value(named: "b")

			XCTAssertEqual(x, 5)
			XCTAssertEqual(y, nil)
		}
	}

	func testDatabaseNamedBindings() {
		let db = try! Database()

		try! db.execute(sql: "create table t1(a, b);")

		for i in 0..<10 {
			try! db.execute(sql: "insert into t1(a, b) values (:b, :a);", parameters: [":a": nil, ":b": i])
		}

		let statement = try! db.prepare(sql: "select * from t1 where a = :a")
		try! statement.bind(value: 5, toParameter: ":a")

		try! statement.execute { row in
			let x: Int = try row.value(at: 0)
			let y: Int? = try row.value(at: 1)

			XCTAssertEqual(x, 5)
			XCTAssertEqual(y, nil)
		}
	}


	func testDatabaseQueue() {
	}

	func testConcurrentDatabaseQueue() {
	}

}
