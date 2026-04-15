#!/usr/bin/env swift

// Generates the three AppIcon PNG variants under
// Recon/Assets.xcassets/AppIcon.appiconset/ from a single SwiftUI view
// so the brand palette is the single source of truth. Run from repo root:
//
//     swift scripts/generate_icon.swift

import AppKit
import CoreGraphics
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

let outputDir = URL(fileURLWithPath: "Recon/Assets.xcassets/AppIcon.appiconset")

let lime = Color(.sRGB, red: 0xC6 / 255.0, green: 0xFF / 255.0, blue: 0x3D / 255.0, opacity: 1)
let nearBlack = Color(.sRGB, red: 0x0B / 255.0, green: 0x0B / 255.0, blue: 0x0C / 255.0, opacity: 1)
let nearWhite = Color(.sRGB, red: 0xFA / 255.0, green: 0xFA / 255.0, blue: 0xF8 / 255.0, opacity: 1)

struct IconView: View {
    let background: Color
    let foreground: Color

    var body: some View {
        ZStack {
            background
            Text("R")
                .font(.system(size: 780, weight: .heavy, design: .rounded))
                .foregroundStyle(foreground)
                .offset(x: 16, y: -20) // visual centring for "R"'s leg
        }
        .frame(width: 1024, height: 1024)
    }
}

@MainActor
func render(_ view: some View, to url: URL) throws {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1

    guard let cgImage = renderer.cgImage else {
        throw NSError(domain: "icon", code: 1, userInfo: [NSLocalizedDescriptionKey: "ImageRenderer returned nil for \(url.lastPathComponent)"])
    }
    guard let dest = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw NSError(domain: "icon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not open destination \(url.path)"])
    }
    CGImageDestinationAddImage(dest, cgImage, nil)
    if !CGImageDestinationFinalize(dest) {
        throw NSError(domain: "icon", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not finalise \(url.lastPathComponent)"])
    }
    print("Wrote \(url.lastPathComponent)")
}

@MainActor
func run() throws {
    try render(
        IconView(background: lime, foreground: nearBlack),
        to: outputDir.appendingPathComponent("AppIcon-1024.png")
    )
    try render(
        IconView(background: nearBlack, foreground: lime),
        to: outputDir.appendingPathComponent("AppIcon-1024-Dark.png")
    )
    try render(
        IconView(background: nearBlack, foreground: nearWhite),
        to: outputDir.appendingPathComponent("AppIcon-1024-Tinted.png")
    )
}

do {
    try MainActor.assumeIsolated {
        try run()
    }
} catch {
    FileHandle.standardError.write("Error: \(error.localizedDescription)\n".data(using: .utf8)!)
    exit(1)
}
