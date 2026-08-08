import Cocoa
import os

enum Log {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "co.waasabi.Lattice", category: "Lattice")

    static func info(_ message: String) {
        logger.info("\(message)")
    }

    static func warn(_ message: String) {
        logger.warning("\(message)")
    }

    static func error(_ message: String) {
        logger.error("\(message)")
    }
}
