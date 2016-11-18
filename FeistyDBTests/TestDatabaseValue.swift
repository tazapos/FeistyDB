//
// Copyright (c) 2015 - 2016 Feisty Dog, LLC
//
// See https://github.com/feistydog/FeistyDB/blob/master/LICENSE.txt for license information
//

import XCTest
@testable import FeistyDB

class TestDatabaseValue: XCTestCase {
    func testDatabaseValue() {
		let db = try! Database()
		try! db.execute(sql: "create table t1(a);")

		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: 33)
		try! db.execute(sql: "select a from t1 order by rowid desc limit 1;") { row in
			row.statement.withUnsafeRawSQLiteStatement { stmt in
				let value = DatabaseValue(sqlite3_column_value(stmt, 0))
				switch value {
				case .integer(let i):
					XCTAssertEqual(i, 33)
				default:
					XCTFail()
				}
			}

			row.statement.withUnsafeRawSQLiteStatement { stmt in
				let value = DatabaseValue(stmt, column: 0)
				switch value {
				case .integer(let i):
					XCTAssertEqual(i, 33)
				default:
					XCTFail()
				}
			}
		}

		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: 33.0)
		try! db.execute(sql: "select a from t1 order by rowid desc limit 1;") { row in
			row.statement.withUnsafeRawSQLiteStatement { stmt in
				let value = DatabaseValue(sqlite3_column_value(stmt, 0))
				switch value {
				case .float(let f):
					XCTAssertEqual(f, 33.0)
				default:
					XCTFail()
				}
			}

			row.statement.withUnsafeRawSQLiteStatement { stmt in
				let value = DatabaseValue(stmt, column: 0)
				switch value {
				case .float(let f):
					XCTAssertEqual(f, 33.0)
				default:
					XCTFail()
				}
			}
		}

		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: "33")
		try! db.execute(sql: "select a from t1 order by rowid desc limit 1;") { row in
			row.statement.withUnsafeRawSQLiteStatement { stmt in
				let value = DatabaseValue(sqlite3_column_value(stmt, 0))
				switch value {
				case .text(let t):
					XCTAssertEqual(t, "33")
				default:
					XCTFail()
				}
			}

			row.statement.withUnsafeRawSQLiteStatement { stmt in
				let value = DatabaseValue(stmt, column: 0)
				switch value {
				case .text(let t):
					XCTAssertEqual(t, "33")
				default:
					XCTFail()
				}
			}
		}

		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: Data([33]))
		try! db.execute(sql: "select a from t1 order by rowid desc limit 1;") { row in
			row.statement.withUnsafeRawSQLiteStatement { stmt in
				let value = DatabaseValue(sqlite3_column_value(stmt, 0))
				switch value {
				case .blob(let b):
					XCTAssertEqual(b, Data([33]))
				default:
					XCTFail()
				}
			}

			row.statement.withUnsafeRawSQLiteStatement { stmt in
				let value = DatabaseValue(stmt, column: 0)
				switch value {
				case .blob(let b):
					XCTAssertEqual(b, Data([33]))
				default:
					XCTFail()
				}
			}
		}

		try! db.execute(sql: "insert into t1(a) values (?);", parameterValues: nil)
		try! db.execute(sql: "select a from t1 order by rowid desc limit 1;") { row in
			row.statement.withUnsafeRawSQLiteStatement { stmt in
				let value = DatabaseValue(sqlite3_column_value(stmt, 0))
				switch value {
				case .null:
					break
				default:
					XCTFail()
				}
			}

			row.statement.withUnsafeRawSQLiteStatement { stmt in
				let value = DatabaseValue(stmt, column: 0)
				switch value {
				case .null:
					break
				default:
					XCTFail()
				}
			}
		}
    }
}
