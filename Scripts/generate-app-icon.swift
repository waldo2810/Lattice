#!/usr/bin/env swift

// Generates the placeholder Lattice app icon PNGs into
// Lattice/Assets.xcassets/AppIcon.appiconset/.
//
// Usage (from the repository root):
//     swift Scripts/generate-app-icon.swift
//
// The artwork is a deliberately simple, flat, grid-themed placeholder so the
// app stops shipping a generic icon. It is NOT a designed icon -- replace it
// with real artwork (ideally a macOS 26 layered `.icon` document) before any
// public release.

import AppKit
import CoreGraphics
import Foundation

// MARK: - Geometry constants (fractions of the full canvas / art box)

/// Apple's macOS icon grid leaves a margin around the rounded-rect body.
private let artInsetFraction: CGFloat = 100.0 / 1024.0
/// Continuous-corner radius of the icon body, as a fraction of the body size.
private let bodyCornerFraction: CGFloat = 0.2237
/// Padding between the icon body and the grid artwork.
private let gridInsetFraction: CGFloat = 0.19
/// Gap between grid cells, as a fraction of the grid box.
private let gridGapFraction: CGFloat = 0.075

private func srgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor {
    CGColor(srgbRed: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1.0)
}

private let gradientTop = srgb(96, 132, 255)
private let gradientBottom = srgb(84, 68, 214)

/// A rounded rect path. Uses `CGPath(roundedRect:)`, which is close enough to
/// the squircle for a placeholder.
private func roundedRect(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

private func drawIcon(into ctx: CGContext, canvas: CGFloat) {
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high

    // MARK: Body

    let inset = canvas * artInsetFraction
    let body = CGRect(x: inset, y: inset, width: canvas - inset * 2, height: canvas - inset * 2)
    let bodyPath = roundedRect(body, radius: body.width * bodyCornerFraction)

    ctx.saveGState()
    ctx.addPath(bodyPath)
    ctx.clip()
    let space = CGColorSpaceCreateDeviceRGB()
    if let gradient = CGGradient(
        colorsSpace: space,
        colors: [gradientTop, gradientBottom] as CFArray,
        locations: [0.0, 1.0]
    ) {
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: body.midX, y: body.maxY),
            end: CGPoint(x: body.midX, y: body.minY),
            options: []
        )
    }
    ctx.restoreGState()

    // MARK: Grid

    let gridInset = body.width * gridInsetFraction
    let grid = body.insetBy(dx: gridInset, dy: gridInset)
    let gap = grid.width * gridGapFraction
    let cell = (grid.width - gap * 2) / 3
    let cellRadius = cell * 0.22

    // Origin of cell (column, row) with row 0 at the top.
    func cellOrigin(column: Int, row: Int) -> CGPoint {
        CGPoint(
            x: grid.minX + CGFloat(column) * (cell + gap),
            y: grid.maxY - CGFloat(row + 1) * cell - CGFloat(row) * gap
        )
    }

    // The 2x2 block in the top-left is a single filled tile: a window occupying
    // a selected region of the grid, which is what Lattice does.
    let blockOrigin = cellOrigin(column: 0, row: 1)
    let blockSide = cell * 2 + gap
    let block = CGRect(x: blockOrigin.x, y: blockOrigin.y, width: blockSide, height: blockSide)
    ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1.0))
    ctx.addPath(roundedRect(block, radius: cellRadius * 1.4))
    ctx.fillPath()

    // The remaining five cells are the empty part of the grid.
    ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.45))
    for row in 0..<3 {
        for column in 0..<3 where !(row < 2 && column < 2) {
            let origin = cellOrigin(column: column, row: row)
            let rect = CGRect(x: origin.x, y: origin.y, width: cell, height: cell)
            ctx.addPath(roundedRect(rect, radius: cellRadius))
            ctx.fillPath()
        }
    }
}

private func renderPNG(pixels: Int) -> Data {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("could not allocate a \(pixels)x\(pixels) bitmap")
    }
    rep.size = NSSize(width: pixels, height: pixels)

    guard let nsContext = NSGraphicsContext(bitmapImageRep: rep) else {
        fatalError("could not create a drawing context")
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = nsContext
    drawIcon(into: nsContext.cgContext, canvas: CGFloat(pixels))
    nsContext.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("could not encode PNG at \(pixels)x\(pixels)")
    }
    return data
}

// MARK: - Asset catalog

/// (point size, scale) pairs, matching the entries in the appiconset.
private let variants: [(points: Int, scale: Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2),
]

private let outputDirectory = URL(fileURLWithPath: "Lattice/Assets.xcassets/AppIcon.appiconset")

guard FileManager.default.fileExists(atPath: outputDirectory.path) else {
    FileHandle.standardError.write(
        Data("error: run this from the repository root (\(outputDirectory.path) not found)\n".utf8)
    )
    exit(1)
}

var entries: [String] = []
// Distinct pixel sizes are rendered once and reused by both entries that need
// them (e.g. 32x32@1x and 16x16@2x are both 32 pixels).
var renderedPixelSizes: Set<Int> = []

for variant in variants {
    let pixels = variant.points * variant.scale
    let filename = "icon_\(pixels).png"
    if !renderedPixelSizes.contains(pixels) {
        let data = renderPNG(pixels: pixels)
        try data.write(to: outputDirectory.appendingPathComponent(filename))
        renderedPixelSizes.insert(pixels)
        print("wrote \(filename) (\(data.count) bytes)")
    }
    entries.append("""
        {
          "filename" : "\(filename)",
          "idiom" : "mac",
          "scale" : "\(variant.scale)x",
          "size" : "\(variant.points)x\(variant.points)"
        }
    """)
}

let contents = """
{
  "images" : [
\(entries.joined(separator: ",\n"))
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

"""
try contents.write(to: outputDirectory.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("wrote Contents.json")
