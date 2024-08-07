import 'package:eagleyeix/metric.dart';

import 'vx_metrics.dart';
import 'vx_model.dart';

/// A generic class to locate and manage validation rules.
///
/// The `VxRuleLocator` stores a map of `VxBaseRule` instances and an `ExMetricStoreHolder`.
/// It also has a default rule to return when a requested rule ID is not found.
class VxRuleLocator<MSG> {
  final VxBaseRule<MSG> defaultRule;
  final ExMetricStoreHolder metricStoreHolder;
  final Map<String, VxBaseRule<MSG>> _rules = {};

  /// Creates a [VxRuleLocator] with a default rule and a metric store holder.
  ///
  /// The [defaultRule] is returned when a requested rule ID is not found.
  /// The [metricStoreHolder] is used to hold and manage metrics.
  VxRuleLocator({
    required this.defaultRule,
    required this.metricStoreHolder,
  });

  /// Registers a [rule] with the given [id].
  ///
  /// If a rule with the same [id] already exists, it will be replaced by the new [rule].
  void registerRule(String id, VxBaseRule<MSG> rule) {
    _rules[id] = rule;
  }

  /// Retrieves a rule by [id].
  ///
  /// Returns the rule associated with the [id] if it exists in the map.
  /// Otherwise, returns the [defaultRule] and logs a metric indicating the rule was not found.
  VxBaseRule<MSG> getRule(String id) {
    final rule = _rules[id];
    if (rule == null) {
      metricStoreHolder.store.addMetric(VxMetrics.getRuleNotFound(id), 1);
      return defaultRule;
    }
    return rule;
  }
}
