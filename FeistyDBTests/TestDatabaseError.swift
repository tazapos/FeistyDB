//
// Copyright (c) 2015 - 2016 Feisty Dog, LLC
//
// See https://github.com/feistydog/FeistyDB/blob/master/LICENSE.txt for license information
//

import XCTest
@testable import FeistyDB

class TestDatabaseError: XCTestCase {
    func testDatabaseError() {
		let message = "error message"
		let e1 = DatabaseError(message)
		XCTAssertEqual(e1.message, message)
		XCTAssertEqual(e1.details, nil)
		XCTAssertEqual(e1.description, message)

		
		let details = "error details"
		let e2 = DatabaseError(message: message, details: details)
		XCTAssertEqual(e2.message, message)
		XCTAssertEqual(e2.details, details)
		XCTAssertEqual(e2.description, "\(message): \(details)")


		var db: OpaquePointer?
		sqlite3_open_v2(":memory:", &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil)
		sqlite3_exec(db, "create t1", nil, nil, nil)
		let e3 = DatabaseError(message: "create failed", takingDescriptionFromDatabase: db!)
		XCTAssertEqual(e3.details, "near \"t1\": syntax error")


		var stmt: OpaquePointer?
		sqlite3_prepare_v2(db, "select count(*) from sqlite_master;", -1, &stmt, nil)
		sqlite3_bind_int(stmt, 3, 3)
		let e4 = DatabaseError(message: "select failed", takingDescriptionFromStatement: stmt!)
		XCTAssertEqual(e4.details, "bind or column index out of range")

		sqlite3_finalize(stmt)
		sqlite3_close(db)
	}
}
