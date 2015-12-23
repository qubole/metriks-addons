# Metriks reporter for OpenTSDB

[![Build Status](https://travis-ci.org/qubole/metriks-addons.svg)](https://travis-ci.org/qubole/metriks-addons)

This is the [metriks](https://github.com/eric/metriks) reporter for
OpenTSDB and SignalFX.
It is heavily inspired from
[Librato Reporter] (https://github.com/eric/metriks-librato_metrics)

## How to use it

Sends metrics to OpenTSDB every 60 seconds.

``` ruby
  reporter = Metriks::OpenTSDBReporter.new(host, port, tags)
  reporter.start
```
1. host: hostname of OpenTSDB
2. port: port on which OpenTSDB
3. tags: A hash of tags that should be associated with every metric.
