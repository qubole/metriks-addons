# Utilities for collecting metrics in a Rails Application

[![Build Status](https://travis-ci.org/qubole/metriks-addons.svg)](https://travis-ci.org/qubole/metriks-addons)

This gem provides utilities for collecting and reporting metrics
in a Rails Application. This gem uses [metriks](https://github.com/eric/metriks).

The first category of utilities is Reporters.

## Reporters
Reporters are available for OpenTSDB, SignalFX and AWS Cloudwatch.
The design is heavily inspired by
[Librato Reporter] (https://github.com/eric/metriks-librato_metrics)

## OpenTSDBReporter

``` ruby
  reporter = Metriks::OpenTSDBReporter.new(host, tags, options)
  reporter.start
```
1. host: hostname of OpenTSDB
2. tags: A hash of tags that should be associated with every metric.
3. options: A hash to control behavior of the reporter. Valid options are:

## SignalFXReporter

``` ruby
  reporter = Metriks::SignalFXReporter.new(token, tags, options = {})
  reporter.start
```

1. token: Token provided by SignalFX
2. tags: A hash of tags that should be associated with every metric.

## CloudWatchReporter

``` ruby
  reporter = Metriks::CloudWatchReporter.new((access_key, secret_key, namespace, tags, options = {}))
  reporter.start
```

1. access_key: Access Key provided by AWS
2. secret_key: Secret Key provided by AWS
3. namespace: AWS CloudWatch namespace of the metric
4. tags: A hash of tags that should be associated with every metric.

## Options

All reporters accept a hash of options. Options are used to control the behavior
of the reporter.

| Option | Description (Default)|
------------------------
| prefix | Add a prefix to the metric name ()|
| batch_size | Number of metrics to report in a API call (50)|
| logger | Logger for debug and info messages (nil) |
| registry | Metriks::Registry to use. (Metriks::Registry.default) |
| interval | Interval between two runs (60 secs) |
