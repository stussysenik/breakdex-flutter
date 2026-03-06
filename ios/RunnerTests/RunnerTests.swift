import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {
  func testPortraitPreferredTransformProducesPositiveCanvas() throws {
    let portraitTransform = CGAffineTransform(
      a: 0,
      b: 1,
      c: -1,
      d: 0,
      tx: 1080,
      ty: 0
    )

    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: portraitTransform,
      userRotation: 0,
      cropRect: nil
    )

    XCTAssertEqual(result.renderSize.width, 1080, accuracy: 0.1)
    XCTAssertEqual(result.renderSize.height, 1920, accuracy: 0.1)

    let transformed = CGRect(
      origin: .zero,
      size: CGSize(width: 1920, height: 1080)
    ).applying(result.transform).standardized
    XCTAssertEqual(transformed.minX, 0, accuracy: 0.1)
    XCTAssertEqual(transformed.minY, 0, accuracy: 0.1)
  }

  func testRotationSwapsCanvasDimensions() throws {
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: .identity,
      userRotation: 90,
      cropRect: nil
    )

    XCTAssertEqual(result.renderSize.width, 1080, accuracy: 0.1)
    XCTAssertEqual(result.renderSize.height, 1920, accuracy: 0.1)

    let transformed = CGRect(
      origin: .zero,
      size: CGSize(width: 1920, height: 1080)
    ).applying(result.transform).standardized
    XCTAssertTrue(
      transformed.intersects(CGRect(origin: .zero, size: result.renderSize))
    )
  }

  func testCropProducesExpectedRenderSize() throws {
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: .identity,
      userRotation: 0,
      cropRect: CGRect(x: 0.25, y: 0.1, width: 0.5, height: 0.5)
    )

    XCTAssertEqual(result.renderSize.width, 960, accuracy: 0.1)
    XCTAssertEqual(result.renderSize.height, 540, accuracy: 0.1)

    let transformed = CGRect(
      origin: .zero,
      size: CGSize(width: 1920, height: 1080)
    ).applying(result.transform).standardized
    XCTAssertTrue(
      transformed.intersects(CGRect(origin: .zero, size: result.renderSize))
    )
  }

  func testTinyCropStillProducesEvenNonZeroRenderSize() throws {
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: .identity,
      userRotation: 0,
      cropRect: CGRect(x: 0.999, y: 0.999, width: 0.001, height: 0.001)
    )

    XCTAssertGreaterThanOrEqual(result.renderSize.width, 2)
    XCTAssertGreaterThanOrEqual(result.renderSize.height, 2)
    XCTAssertEqual(Int(result.renderSize.width) % 2, 0)
    XCTAssertEqual(Int(result.renderSize.height) % 2, 0)
  }

  func testExample() {
    // If you add code to the Runner application, consider adding tests here.
    // See https://developer.apple.com/documentation/xctest for more information about using XCTest.
  }

}
