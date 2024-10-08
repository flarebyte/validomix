import 'package:eagleyeix/metric.dart';

import 'vx_component_name_manager.dart';
import 'vx_metrics.dart';
import 'vx_options_inventory.dart';

/// The status of a map value.
enum VxMapValueStatus { ok, ko, fallback }

/// A map value.
class VxMapValue<T> {
  final T value;
  final VxMapValueStatus status;
  VxMapValue(this.value, this.status);

  /// Creates a new valid [VxMapValue] with the given [value].
  static VxMapValue<T> ok<T>(T value) {
    return VxMapValue<T>(value, VxMapValueStatus.ok);
  }

  /// Creates a new invalid [VxMapValue] with the given [value].
  static VxMapValue<T> ko<T>(T value) {
    return VxMapValue<T>(value, VxMapValueStatus.ko);
  }

  /// Creates a new fallback [VxMapValue] with the given [value].
  static VxMapValue<T> fallback<T>(T value) {
    return VxMapValue<T>(value, VxMapValueStatus.fallback);
  }
}

/// A map of options used for configuration of the validating rules.
class VxOptionsMap {
  final VxComponentManagerConfig componentManagerConfig;
  final ExMetricStoreHolder metricStoreHolder;
  final VxOptionsInventory optionsInventory;
  final String ownerClassName;
  final String? classSpecialisation;
  VxOptionsMap(
      {required this.metricStoreHolder,
      required this.optionsInventory,
      required this.ownerClassName,
      this.componentManagerConfig = VxComponentManagerConfig.defaultConfig,
      this.classSpecialisation});

  VxMapValue<String> _getString(
      {required Map<String, String> options,
      required int id,
      String defaultValue = ''}) {
    final key = optionsInventory.getKey(id);
    final missingKey = !options.containsKey(key.name);
    if (missingKey) {
      if (VxComponentNameManager.hasMandatoryOption(
          key.name, componentManagerConfig)) {
        metricStoreHolder.store.addMetric(
            VxMetrics.getKeyNotFound(
              className: ownerClassName,
              name: key.name,
              specialisation: classSpecialisation,
              page: options['page'],
              pageRow: options['pageRow'],
            ),
            1);
        return VxMapValue.ko(defaultValue);
      }
      return VxMapValue.fallback(defaultValue);
    }

    final value = options[key.name] ?? defaultValue;
    return VxMapValue.ok(value);
  }

  /// Returns the value of the option with the given id, or the default
  VxMapValue<String> getString(
      {required Map<String, String> options,
      required int id,
      String defaultValue = ''}) {
    final resultValue =
        _getString(options: options, id: id, defaultValue: defaultValue);
    if (resultValue.status != VxMapValueStatus.ok) {
      return resultValue;
    }
    final value = resultValue.value;
    final key = optionsInventory.getKey(id);
    final shouldNotBeEmpty =
        key.descriptors.contains(VxOptionsInventoryDescriptors.notBlank) &&
            value.trim() == '';
    if (shouldNotBeEmpty) {
      metricStoreHolder.store.addMetric(
          VxMetrics.getKeyValueBlank(
              className: ownerClassName,
              name: key.name,
              specialisation: classSpecialisation,
              page: options['page'],
              pageRow: options['pageRow']),
          1);
      return VxMapValue.ko(defaultValue);
    }
    return VxMapValue.ok(value);
  }

  /// Returns the integer value of the option with the given id, or the default
  VxMapValue<int> getInt(
      {required Map<String, String> options,
      required int id,
      int defaultValue = 0}) {
    final resultValue =
        _getString(options: options, id: id, defaultValue: "$defaultValue");
    if (resultValue.status != VxMapValueStatus.ok) {
      return VxMapValue(defaultValue, resultValue.status);
    }
    final value = resultValue.value;
    final key = optionsInventory.getKey(id);
    final intValue = int.tryParse(value);
    if (intValue == null) {
      metricStoreHolder.store.addMetric(
          VxMetrics.getKeyValueNotInt(
              className: ownerClassName,
              name: key.name,
              specialisation: classSpecialisation,
              page: options['page'],
              pageRow: options['pageRow']),
          1);
      return VxMapValue.ko(defaultValue);
    }
    if (!key.descriptors.contains(VxOptionsInventoryDescriptors.integer)) {
      metricStoreHolder.store.addMetric(
          VxMetrics.getKeyValueNotInDeclaration(
              className: ownerClassName,
              name: key.name,
              expected: VxOptionsInventoryDescriptors.integer,
              specialisation: classSpecialisation,
              page: options['page'],
              pageRow: options['pageRow']),
          1);
    }
    final shouldbePositive =
        key.descriptors.contains(VxOptionsInventoryDescriptors.positive) &&
            intValue < 0;
    if (shouldbePositive) {
      metricStoreHolder.store.addMetric(
          VxMetrics.getKeyValueNotPositive(
              className: ownerClassName,
              name: key.name,
              specialisation: classSpecialisation,
              page: options['page'],
              pageRow: options['pageRow']),
          1);
      return VxMapValue.ko(defaultValue);
    }
    return VxMapValue.ok(intValue);
  }

  ///   Returns the number value of the option with the given id, or the default
  VxMapValue<num> getNumber(
      {required Map<String, String> options,
      required int id,
      num defaultValue = 0}) {
    final resultValue =
        _getString(options: options, id: id, defaultValue: "$defaultValue");
    if (resultValue.status != VxMapValueStatus.ok) {
      return VxMapValue(defaultValue, resultValue.status);
    }
    final value = resultValue.value;
    final key = optionsInventory.getKey(id);

    final numValue = num.tryParse(value);
    if (numValue == null) {
      metricStoreHolder.store.addMetric(
          VxMetrics.getKeyValueNotInt(
              className: ownerClassName,
              name: key.name,
              specialisation: classSpecialisation,
              page: options['page'],
              pageRow: options['pageRow']),
          1);
      return VxMapValue.ko(defaultValue);
    }
    if (!(key.descriptors.contains(VxOptionsInventoryDescriptors.numeric) ||
        key.descriptors.contains(VxOptionsInventoryDescriptors.integer))) {
      metricStoreHolder.store.addMetric(
          VxMetrics.getKeyValueNotInDeclaration(
              className: ownerClassName,
              name: key.name,
              expected: VxOptionsInventoryDescriptors.numeric,
              specialisation: classSpecialisation,
              page: options['page'],
              pageRow: options['pageRow']),
          1);
    }
    final shouldbePositive =
        key.descriptors.contains(VxOptionsInventoryDescriptors.positive) &&
            numValue < 0;
    if (shouldbePositive) {
      metricStoreHolder.store.addMetric(
          VxMetrics.getKeyValueNotPositive(
              className: ownerClassName,
              name: key.name,
              specialisation: classSpecialisation,
              page: options['page'],
              pageRow: options['pageRow']),
          1);
      return VxMapValue.ko(defaultValue);
    }
    return VxMapValue.ok(numValue);
  }

  ///   Returns the boolean value of the option with the given id, or the default
  VxMapValue<bool> getBoolean(
      {required Map<String, String> options,
      required int id,
      bool defaultValue = false}) {
    final resultValue =
        _getString(options: options, id: id, defaultValue: "$defaultValue");
    if (resultValue.status != VxMapValueStatus.ok) {
      return VxMapValue(defaultValue, resultValue.status);
    }
    final value = resultValue.value;
    final key = optionsInventory.getKey(id);
    final boolValue = bool.tryParse(value);
    if (boolValue == null) {
      metricStoreHolder.store.addMetric(
          VxMetrics.getKeyValueNotBool(
              className: ownerClassName,
              name: key.name,
              specialisation: classSpecialisation,
              page: options['page'],
              pageRow: options['pageRow']),
          1);
      return VxMapValue.ko(defaultValue);
    }

    if (!key.descriptors.contains(VxOptionsInventoryDescriptors.boolean)) {
      metricStoreHolder.store.addMetric(
          VxMetrics.getKeyValueNotInDeclaration(
              className: ownerClassName,
              name: key.name,
              expected: VxOptionsInventoryDescriptors.boolean,
              specialisation: classSpecialisation,
              page: options['page'],
              pageRow: options['pageRow']),
          1);
    }
    return VxMapValue.ok(boolValue);
  }

  static const List<String> emptyList = [];

  /// Returns the value of the option with the given id, or the default
  VxMapValue<List<String>> getStringList(
      {required Map<String, String> options,
      required int id,
      String separator = ' ',
      List<String> defaultValue = emptyList}) {
    final resultValue =
        _getString(options: options, id: id, defaultValue: "$defaultValue");
    if (resultValue.status != VxMapValueStatus.ok) {
      return VxMapValue(defaultValue, resultValue.status);
    }
    final key = optionsInventory.getKey(id);
    if (!key.descriptors.contains(VxOptionsInventoryDescriptors.stringList)) {
      metricStoreHolder.store.addMetric(
          VxMetrics.getKeyValueNotInDeclaration(
              className: ownerClassName,
              name: key.name,
              expected: VxOptionsInventoryDescriptors.stringList,
              specialisation: classSpecialisation,
              page: options['page'],
              pageRow: options['pageRow']),
          1);
    }
    final value = resultValue.value;
    final stringsValue = value.split(separator);
    return VxMapValue.ok(stringsValue);
  }
}
