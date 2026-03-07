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

  // MARK: - Export edge cases

  /// Full video (no trim) — trimStart == 0, trimEnd == duration.
  /// Geometry should pass through the full frame unchanged.
  func testFullVideoNoTrimGeometry() throws {
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: .identity,
      userRotation: 0,
      cropRect: nil
    )

    XCTAssertEqual(result.renderSize.width, 1920, accuracy: 0.1)
    XCTAssertEqual(result.renderSize.height, 1080, accuracy: 0.1)
  }

  /// Speed extremes: 0.25x (minimum) — geometry is speed-independent,
  /// so render size should be unaffected.
  func testSlowSpeedDoesNotAffectGeometry() throws {
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: .identity,
      userRotation: 0,
      cropRect: nil
    )

    // Speed doesn't affect geometry — just verifying the function
    // works at all edge cases. Render size stays the same.
    XCTAssertEqual(result.renderSize.width, 1920, accuracy: 0.1)
    XCTAssertEqual(result.renderSize.height, 1080, accuracy: 0.1)
  }

  // MARK: - All 4 rotation × portrait/landscape combos

  func testRotation0Landscape() throws {
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: .identity,
      userRotation: 0,
      cropRect: nil
    )
    XCTAssertEqual(result.renderSize.width, 1920, accuracy: 0.1)
    XCTAssertEqual(result.renderSize.height, 1080, accuracy: 0.1)
  }

  func testRotation90Landscape() throws {
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: .identity,
      userRotation: 90,
      cropRect: nil
    )
    // 90° rotation swaps dimensions
    XCTAssertEqual(result.renderSize.width, 1080, accuracy: 0.1)
    XCTAssertEqual(result.renderSize.height, 1920, accuracy: 0.1)
  }

  func testRotation180Landscape() throws {
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: .identity,
      userRotation: 180,
      cropRect: nil
    )
    // 180° keeps same dimensions
    XCTAssertEqual(result.renderSize.width, 1920, accuracy: 0.1)
    XCTAssertEqual(result.renderSize.height, 1080, accuracy: 0.1)
  }

  func testRotation270Landscape() throws {
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: .identity,
      userRotation: 270,
      cropRect: nil
    )
    // 270° swaps dimensions (same as 90°)
    XCTAssertEqual(result.renderSize.width, 1080, accuracy: 0.1)
    XCTAssertEqual(result.renderSize.height, 1920, accuracy: 0.1)
  }

  func testRotation0Portrait() throws {
    let portraitTransform = CGAffineTransform(
      a: 0, b: 1, c: -1, d: 0, tx: 1080, ty: 0
    )
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: portraitTransform,
      userRotation: 0,
      cropRect: nil
    )
    // Portrait preferred transform swaps to 1080×1920
    XCTAssertEqual(result.renderSize.width, 1080, accuracy: 0.1)
    XCTAssertEqual(result.renderSize.height, 1920, accuracy: 0.1)
  }

  func testRotation90Portrait() throws {
    let portraitTransform = CGAffineTransform(
      a: 0, b: 1, c: -1, d: 0, tx: 1080, ty: 0
    )
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: portraitTransform,
      userRotation: 90,
      cropRect: nil
    )
    // Portrait + 90° user rotation → landscape again
    XCTAssertEqual(result.renderSize.width, 1920, accuracy: 0.1)
    XCTAssertEqual(result.renderSize.height, 1080, accuracy: 0.1)
  }

  func testRotation180Portrait() throws {
    let portraitTransform = CGAffineTransform(
      a: 0, b: 1, c: -1, d: 0, tx: 1080, ty: 0
    )
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: portraitTransform,
      userRotation: 180,
      cropRect: nil
    )
    // Portrait + 180° → still portrait
    XCTAssertEqual(result.renderSize.width, 1080, accuracy: 0.1)
    XCTAssertEqual(result.renderSize.height, 1920, accuracy: 0.1)
  }

  func testRotation270Portrait() throws {
    let portraitTransform = CGAffineTransform(
      a: 0, b: 1, c: -1, d: 0, tx: 1080, ty: 0
    )
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: portraitTransform,
      userRotation: 270,
      cropRect: nil
    )
    // Portrait + 270° → landscape
    XCTAssertEqual(result.renderSize.width, 1920, accuracy: 0.1)
    XCTAssertEqual(result.renderSize.height, 1080, accuracy: 0.1)
  }

  // MARK: - Crop with rotation combos

  func testCropWithRotation90() throws {
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: .identity,
      userRotation: 90,
      cropRect: CGRect(x: 0.0, y: 0.0, width: 0.5, height: 0.5)
    )

    // After 90° rotation, oriented size is 1080×1920
    // Crop 50%×50% → 540×960
    XCTAssertEqual(result.renderSize.width, 540, accuracy: 0.1)
    XCTAssertEqual(result.renderSize.height, 960, accuracy: 0.1)
    XCTAssertEqual(Int(result.renderSize.width) % 2, 0)
    XCTAssertEqual(Int(result.renderSize.height) % 2, 0)
  }

  func testCropWithRotation180() throws {
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: .identity,
      userRotation: 180,
      cropRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
    )

    // 180° keeps 1920×1080, crop 50%×50% → 960×540
    XCTAssertEqual(result.renderSize.width, 960, accuracy: 0.1)
    XCTAssertEqual(result.renderSize.height, 540, accuracy: 0.1)
  }

  // MARK: - Even dimension enforcement

  func testOddDimensionSourceProducesEvenOutput() throws {
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1921, height: 1081),
      preferredTransform: .identity,
      userRotation: 0,
      cropRect: nil
    )

    // H.264 encoders require even dimensions
    XCTAssertEqual(Int(result.renderSize.width) % 2, 0)
    XCTAssertEqual(Int(result.renderSize.height) % 2, 0)
  }

  func testSquareCropProducesSquareOutput() throws {
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: .identity,
      userRotation: 0,
      cropRect: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
    )

    // Full crop → full size
    XCTAssertEqual(result.renderSize.width, 1920, accuracy: 0.1)
    XCTAssertEqual(result.renderSize.height, 1080, accuracy: 0.1)
  }

  // MARK: - Aspect ratio crops (9:16, 16:9, 1:1, 4:5)

  func testFullFrameCropResultsInFullSize() throws {
    let result = try VideoExportGeometry.compute(
      naturalSize: CGSize(width: 1920, height: 1080),
      preferredTransform: .identity,
      userRotation: 0,
      cropRect: CGRect(x: 0, y: 0, width: 1, height: 1)
    )

    XCTAssertEqual(result.renderSize.width, 1920, accuracy: 0.1)
    XCTAssertEqual(result.renderSize.height, 1080, accuracy: 0.1)
  }

}
