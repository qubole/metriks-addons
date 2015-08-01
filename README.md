# Metriks reporter for OpenTSDB

This is the [metriks](https://github.com/eric/metriks) reporter for OpenTSDB Metrics.
It is heavily inspired from
[Librato Reporter] (https://github.com/eric/metriks-librato_metrics)

## How to use it

Sends metrics to OpenTSDB every 60 seconds.

``` ruby
  reporter = Metriks::OpenTSDBReporter.new('email', 'token')
  reporter.start
```

# License

Copyright (c) 2015 Rajat Venkatesh

Published under the Apache 2.0 License, see LICENSE
