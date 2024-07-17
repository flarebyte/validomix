import 'package:eagleyeix/metric.dart';

import 'vx_component_name_manager.dart';
import 'vx_metrics.dart';
import 'vx_options_inventory.dart';

enum VxMapValueStatus { ok, ko, fallback }

class VxMapValue<T> {
  final T value;
  final VxMapValueStatus status;
  VxMapValue(this.value, this.status);
  static VxMapValue<T> ok<T>(T value) {
    return VxMapValue<T>(value, VxMapValueStatus.ok);
  }

  static VxMapValue<T> ko<T>(T value) {
    return VxMapValue<T>(value, VxMapValueStatus.ok);
  }

  static VxMapValue<T> fallback<T>(T value) {
    return VxMapValue<T>(value, VxMapValueStatus.fallback);
  }
}

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
                specialisation: classSpecialisation),
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
              specialisation: classSpecialisation),
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
              specialisation: classSpecialisation),
          1);
      return VxMapValue.ko(defaultValue);
    }

    final shouldbePositive =
        key.descriptors.contains(VxOptionsInventoryDescriptors.positive) &&
            intValue < 0;
    if (shouldbePositive) {
      metricStoreHolder.store.addMetric(
          VxMetrics.getKeyValueNotPositive(
              className: ownerClassName,
              name: key.name,
              specialisation: classSpecialisation),
          1);
      return VxMapValue.ko(defaultValue);
    }
    return VxMapValue.ok(intValue);
  }

  ///   Returns the number value of the option with the given id, or the default
  num getNumber(
      {required Map<String, String> options,
      required int id,
      int defaultValue = 0}) {
    final key = optionsInventory.getKey(id);
    final missingMandatoryKey =
        VxComponentNameManager.hasMandatoryOption(key.name) &&
            (!options.containsKey(key.name));
    if (missingMandatoryKey) {
      metricStoreHolder.store.addMetric(
          VxMetrics.getKeyNotFound(
              className: ownerClassName,
              name: key.name,
              specialisation: classSpecialisation),
          1);
      return defaultValue;
    }
    final value = options[key.name] ?? "$defaultValue";
    final intValue = num.tryParse(value);
    if (intValue == null) {
      metricStoreHolder.store.addMetric(
          VxMetrics.getKeyValueNotNum(
              className: ownerClassName,
              name: key.name,
              specialisation: classSpecialisation),
          1);
      return defaultValue;
    }

    final shouldbePositive =
        key.descriptors.contains(VxOptionsInventoryDescriptors.positive) &&
            intValue < 0;
    if (shouldbePositive) {
      metricStoreHolder.store.addMetric(
          VxMetrics.getKeyValueNotPositive(
              className: ownerClassName,
              name: key.name,
              specialisation: classSpecialisation),
          1);
      return defaultValue;
    }
    return intValue;
  }

  ///   Returns the boolean value of the option with the given id, or the default
  bool getBoolean(
      {required Map<String, String> options,
      required int id,
      bool defaultValue = false}) {
    final key = optionsInventory.getKey(id);
    final missingMandatoryKey =
        VxComponentNameManager.hasMandatoryOption(key.name) &&
            (!options.containsKey(key.name));
    if (missingMandatoryKey) {
      metricStoreHolder.store.addMetric(
          VxMetrics.getKeyNotFound(
              className: ownerClassName,
              name: key.name,
              specialisation: classSpecialisation),
          1);
      return defaultValue;
    }
    final value = options[key.name] ?? "$defaultValue";
    final boolValue = bool.tryParse(value);
    if (boolValue == null) {
      metricStoreHolder.store.addMetric(
          VxMetrics.getKeyValueNotNum(
              className: ownerClassName,
              name: key.name,
              specialisation: classSpecialisation),
          1);
      return defaultValue;
    }

    return boolValue;
  }

  static const List<String> emptyList = [];

  /// Returns the value of the option with the given id, or the default
  List<String> getStringList(
      {required Map<String, String> options,
      required int id,
      String separator = ' ',
      List<String> defaultValue = emptyList}) {
    final key = optionsInventory.getKey(id);
    final missingMandatoryKey =
        VxComponentNameManager.hasMandatoryOption(key.name) &&
            (!options.containsKey(key.name));
    if (missingMandatoryKey) {
      metricStoreHolder.store.addMetric(
          VxMetrics.getKeyNotFound(
              className: ownerClassName,
              name: key.name,
              specialisation: classSpecialisation),
          1);
      return defaultValue;
    }
    final value = options[key.name] ?? '';
    final stringsValue = value.split(separator);
    return stringsValue;
  }
}