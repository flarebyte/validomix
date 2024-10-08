import 'package:eagleyeix/metric.dart';

import '../validomix.dart';

/// Validates a URL.
class VxUrlRule<MSG> extends VxBaseRule<MSG> {
  final List<VxMessageProducer<MSG, String>>? successProducers;
  final List<VxMessageProducer<MSG, String>>? failureProducers;
  final List<VxMessageProducer<MSG, String>>? secureFailureProducers;
  final List<VxMessageProducer<MSG, String>>? domainFailureProducers;
  final String name;
  final ExMetricStoreHolder metricStoreHolder;
  final VxComponentManagerConfig componentManagerConfig;
  final VxOptionsInventory optionsInventory;
  late VxOptionsMap optionsMap;
  late int allowFragmentKey;
  late int allowQueryKey;
  late int allowDomainsKey;
  late int secureKey;
  late int allowIPKey;

  VxUrlRule(
      {required this.name,
      required this.metricStoreHolder,
      required this.optionsInventory,
      this.successProducers,
      this.failureProducers,
      this.secureFailureProducers,
      this.domainFailureProducers,
      this.componentManagerConfig = VxComponentManagerConfig.defaultConfig}) {
    optionsMap = VxOptionsMap(
        metricStoreHolder: metricStoreHolder,
        optionsInventory: optionsInventory,
        ownerClassName: 'VxUrlRule',
        componentManagerConfig: componentManagerConfig);
    allowFragmentKey = optionsInventory.addKey(
        VxComponentNameManager.getFullOptionKey(name, 'allowFragment',
            optional: true),
        [VxOptionsInventoryDescriptors.boolean]);
    allowQueryKey = optionsInventory.addKey(
        VxComponentNameManager.getFullOptionKey(name, 'allowQuery',
            optional: true),
        [VxOptionsInventoryDescriptors.boolean]);
    allowIPKey = optionsInventory.addKey(
        VxComponentNameManager.getFullOptionKey(name, 'allowIP',
            optional: true),
        [VxOptionsInventoryDescriptors.boolean]);
    secureKey = optionsInventory.addKey(
        VxComponentNameManager.getFullOptionKey(name, 'secure', optional: true),
        [VxOptionsInventoryDescriptors.boolean]);
    allowDomainsKey = optionsInventory.addKey(
        VxComponentNameManager.getFullOptionKey(name, 'allowDomains',
            optional: true),
        [VxOptionsInventoryDescriptors.stringList]);
  }

  List<MSG> _produceSuccess(Map<String, String> options, String value) {
    return successProducers == null
        ? []
        : successProducers!
            .map((prod) => prod.produce(options, value))
            .toList();
  }

  List<MSG> _produceFailure(Map<String, String> options, String value) {
    return failureProducers == null
        ? []
        : failureProducers!
            .map((prod) => prod.produce(options, value))
            .toList();
  }

  List<MSG> _produceSecureFailure(Map<String, String> options, String value) {
    return secureFailureProducers == null
        ? _produceFailure(options, value)
        : secureFailureProducers!
            .map((prod) => prod.produce(options, value))
            .toList();
  }

  List<MSG> _produceDomainFailure(Map<String, String> options, String value) {
    return domainFailureProducers == null
        ? _produceFailure(options, value)
        : domainFailureProducers!
            .map((prod) => prod.produce(options, value))
            .toList();
  }

  bool _endsWithAnyDomain(String host, List<String> allowedEndings) {
    return allowedEndings.any((ending) => host.endsWith(ending));
  }

  bool _isIPv4(String host) {
    final ipv4Regex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    return ipv4Regex.hasMatch(host);
  }

  bool _isIPv6(String host) {
    return host.contains(':') && !host.contains('.');
  }

  @override
  List<MSG> validate(Map<String, String> options, String value) {
    final uri = Uri.tryParse(value);

    if (uri == null) {
      return _produceFailure(options, value);
    }
    if (!(uri.isScheme('http') || uri.isScheme('https'))) {
      return _produceFailure(options, value);
    }
    final secure = optionsMap.getBoolean(options: options, id: secureKey).value;
    if (secure && !uri.isScheme('https')) {
      return _produceSecureFailure(options, value);
    }
    if (uri.hasPort) {
      return _produceFailure(options, value);
    }
    if (uri.userInfo.isNotEmpty) {
      return _produceFailure(options, value);
    }
    final allowFragment =
        optionsMap.getBoolean(options: options, id: allowFragmentKey).value;
    if (!allowFragment && uri.hasFragment) {
      return _produceFailure(options, value);
    }
    final allowQuery =
        optionsMap.getBoolean(options: options, id: allowQueryKey).value;
    if (!allowQuery && uri.hasQuery) {
      return _produceFailure(options, value);
    }
    final allowDomains =
        optionsMap.getStringList(options: options, id: allowDomainsKey).value;
    if (allowDomains.isNotEmpty &&
        !_endsWithAnyDomain(uri.host, allowDomains)) {
      return _produceDomainFailure(options, value);
    }
    final allowIP =
        optionsMap.getBoolean(options: options, id: allowIPKey).value;
    if ((_isIPv4(uri.host) || _isIPv6(uri.host)) && !allowIP) {
      return _produceFailure(options, value);
    }

    return _produceSuccess(options, value);
  }
}
