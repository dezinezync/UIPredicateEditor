#if os(iOS)
import Foundation

/// Optional methods implemented by parties interested in updates to a `PredicateController`
///
/// - note: Not marked `@objc`, so conforming types do not need to also conform to `NSObjectProtocol`.
///   The default implementation makes it so the implementer is only required to respond to 'didChange'
///   events.
@MainActor public protocol PredicateControllerDelegate {
  /// Informs the receiver that a predicate is about to change.
  func predicateWillChangeForPredicateController(_ predicateController: PredicateController)

  /// Informs the receiver that a predicate has been changed.
  func predicateDidChangeForPredicateController(_ predicateController: PredicateController)
}

// MARK: - Default Implementation

public extension PredicateControllerDelegate {
  func predicateWillChangeForPredicateController(_: PredicateController) {}
}
#endif
