#!/usr/bin/env swift

import CoreGraphics
import Darwin
import Foundation
import ImageIO
import UniformTypeIdentifiers

typealias WindowImageFunction = @convention(c) (
    CGRect,
    CGWindowListOption,
    CGWindowID,
    CGWindowImageOption) -> Unmanaged<CGImage>?

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    FileHandle.standardError.write(Data("Usage: capture_quotaroom_menu.swift /absolute/output.png\n".utf8))
    exit(2)
}

guard arguments[1].hasPrefix("/") else {
    FileHandle.standardError.write(Data("Output must be an absolute PNG path.\n".utf8))
    exit(2)
}
let outputURL = URL(fileURLWithPath: arguments[1])
guard outputURL.pathExtension.lowercased() == "png" else {
    FileHandle.standardError.write(Data("Output must use the .png extension.\n".utf8))
    exit(2)
}

let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
let menuWindows = windows.compactMap { window -> (id: CGWindowID, bounds: CGRect)? in
    guard window[kCGWindowOwnerName as String] as? String == "QuotaRoom",
          window[kCGWindowLayer as String] as? Int == 101,
          let number = window[kCGWindowNumber as String] as? UInt32,
          let boundsDictionary = window[kCGWindowBounds as String] as? [String: Any],
          let bounds = CGRect(dictionaryRepresentation: boundsDictionary as CFDictionary)
    else { return nil }
    return (CGWindowID(number), bounds)
}

guard menuWindows.count == 1, let menuWindow = menuWindows.first else {
    FileHandle.standardError.write(
        Data("Expected one open QuotaRoom status menu; found \(menuWindows.count).\n".utf8))
    exit(1)
}

guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CGWindowListCreateImage") else {
    FileHandle.standardError.write(Data("CoreGraphics window capture is unavailable.\n".utf8))
    exit(1)
}
let createWindowImage = unsafeBitCast(symbol, to: WindowImageFunction.self)
guard let unmanagedImage = createWindowImage(
    .null,
    [.optionIncludingWindow],
    menuWindow.id,
    [.boundsIgnoreFraming])
else {
    FileHandle.standardError.write(Data("Could not capture the QuotaRoom menu window.\n".utf8))
    exit(1)
}

let image = unmanagedImage.takeRetainedValue()
guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil)
else {
    FileHandle.standardError.write(Data("Could not create the PNG destination.\n".utf8))
    exit(1)
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    FileHandle.standardError.write(Data("Could not write the PNG.\n".utf8))
    exit(1)
}
try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: outputURL.path)

print("Captured QuotaRoom menu \(image.width)x\(image.height) at \(outputURL.path)")
