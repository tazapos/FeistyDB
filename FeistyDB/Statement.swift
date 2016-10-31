/*
 *  Copyright (C) 2015, 2016 Feisty Dog, LLC
 *  All Rights Reserved
 */

import Foundation

/// A class representing an SQL statement with support for binding SQL parameters and retrieving results.
final public class Statement {
	/// The underlying `sqlite3_stmt *` object
	var stmt: OpaquePointer

	/// Initialize a new statement with a compiled SQL statement
	///
	/// - parameter statement: An `sqlite3_stmt *` object
	init(_ statement: OpaquePointer) {
		stmt = statement
	}

	deinit {
		sqlite3_finalize(stmt)
	}

	/// `true` if this statement makes no direct changes to the database, `false` otherwise.
	///
	/// - seealso: [Read-only statements in SQLite](http://sqlite.org/c3ref/stmt_readonly.html)
	public var readOnly: Bool {
		return sqlite3_stmt_readonly(stmt) != 0
	}

	/// The number of SQL parameters in this statement
	public var parameterCount: Int {
		return Int(sqlite3_bind_parameter_count(stmt))
	}

	/// The original SQL text of the statement
	public var sql: String {
		return String(cString: sqlite3_sql(stmt))
	}

	/// The SQL text of the statement with bound parameters expanded
	public var expandedSQL: String {
		return String(cString: sqlite3_expanded_sql(stmt))
	}

	/// The number of columns in the result set
	public var columnCount: Int {
		return Int(sqlite3_column_count(stmt))
	}

	/// The mapping of column names to indexes
	var columnNamesAndIndexes: [String: Int32] {
		let columnCount = sqlite3_column_count(stmt)
		var map = [String: Int32](minimumCapacity: Int(sqlite3_column_count(stmt)))
		for i in 0..<columnCount {
			let name = String(cString: sqlite3_column_name(stmt, i))
			map[name] = i
		}
		return map
	}

	/// Execute the statement without returning a result set
	///
	/// - throws: `DatabaseError`
	public func execute() throws {
		try results { _ in }
	}

	/// Iterate through the rows in the result set
	///
	/// - parameter block: A block called for each row
	/// - parameter row: A `Row` object representing a row of returned data
	/// - throws: `DatabaseError`
	public func results(row block: (_ row: Row) -> ()) throws {
		var result = sqlite3_step(stmt)
		while result == SQLITE_ROW {
			block(Row(self))
			result = sqlite3_step(stmt)
		}

		if result != SQLITE_DONE {
			#if DEBUG
				print("Error executing statement: \(String(cString: sqlite3_errmsg(sqlite3_db_handle(stmt))))")
			#endif
			throw DatabaseError.sqliteError(String(cString: sqlite3_errmsg(sqlite3_db_handle(stmt))))
		}
	}

	/// Reset the statement to its initial state
	///
	/// - throws: `DatabaseError`
	public func reset() throws {
		if sqlite3_reset(stmt) != SQLITE_OK {
			#if DEBUG
				print("Error resetting statement: \(String(cString: sqlite3_errmsg(sqlite3_db_handle(stmt))))")
			#endif
			throw DatabaseError.sqliteError(String(cString: sqlite3_errmsg(sqlite3_db_handle(stmt))))
		}
	}

	/// Clear all statement bindings
	///
	/// - throws: `DatabaseError`
	public func clear() throws {
		if sqlite3_clear_bindings(stmt) != SQLITE_OK {
			#if DEBUG
				print("Error clearing bindings: \(String(cString: sqlite3_errmsg(sqlite3_db_handle(stmt))))")
			#endif
			throw DatabaseError.sqliteError(String(cString: sqlite3_errmsg(sqlite3_db_handle(stmt))))
		}
	}

	/// Perform a low-level statement operation
	///
	/// **Use of this function should be avoided whenever possible**
	///
	/// - parameter block: The block performing the operation
	/// - parameter statement: The raw `sqlite3_stmt *` statement object
	/// - throws: Any error thrown in `block`
	/// - returns: The value returned by `block`
	public func withUnsafeRawSQLiteStatement<T>(block: (_ statement: OpaquePointer) throws -> (T)) rethrows -> T {
		return try block(stmt)
	}
}

/// Access rows in a result set as a `Sequence`
extension Statement {
	/// Get a sequence for accessing the rows in the result set
	///
	/// Because the underlying iterator discards errors, the preferred way for accessing rows is
	/// via the block-based `results(row:)` function
	///
	/// - returns: A sequence for accessing the rows in the result set
	public func results() -> AnySequence<Row> {
		return AnySequence {
			return AnyIterator {
				let stmt = self.stmt
				switch sqlite3_step(stmt) {
				case SQLITE_ROW:
					return Row(self)
				case SQLITE_DONE:
					return nil
				default:
					#if DEBUG
						print("Error executing statement: \(String(cString: sqlite3_errmsg(sqlite3_db_handle(stmt))))")
					#endif
					return nil
				}
			}
		}
	}
}
