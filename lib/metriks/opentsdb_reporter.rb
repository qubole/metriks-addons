require 'metriks/time_tracker'
require 'rest-client'

module Metriks
  class OpenTSDBReporter
    attr_accessor :prefix, :source, :data, :hostname, :tags

    def initialize(h, t, options = {})
      @hostname = h
      @tags = t

      @prefix = options[:prefix]
      @source = options[:source]

      @logger       = options[:logger] || nil
      @batch_size   = options[:batch_size] || 50
      @registry     = options[:registry] || Metriks::Registry.default
      @interval     = options[:interval] || 60
      @time_tracker = Metriks::TimeTracker.new(@interval)
      @on_error     = options[:on_error] || proc { |ex| }

      if options[:percentiles]
        @percentiles = options[:percentiles]
      else
        @percentiles = [ 0.95, 0.99]
      end

      @mutex = Mutex.new
      @running = false
    end

    def info(msg)
      if !@logger.nil?
        @logger.info(msg)
      end
    end

    def start
      if @thread && @thread.alive?
        return
      end

      @running = true
      @thread = Thread.new do
        while @running
          @time_tracker.sleep

          Thread.new do
            flush
          end
        end
      end
    end

    def stop
      @running = false

      if @thread
        @thread.join
        @thread = nil
      end
    end

    def restart
      stop
      start
    end

    def flush
      begin
        @mutex.synchronize do
          info("Flushing metrics")
          submit get_datapoints
        end
      rescue Exception => ex
        if !@logger.nil?
          @logger.error(ex.message)
          @logger.error(ex.stacktrace)
        end
        @on_error[ex] rescue nil
      end
    end

    def submit(datapoints)
      return if datapoints.empty?

      index = 0
      length = @batch_size
      while index < datapoints.size
        if datapoints.size < (index + length)
          length = datapoints.size - index
        else
          length = @batch_size
        end

        RestClient.post "#{@hostname}/api/put",
          datapoints[index, length].to_json,
          :content_type => :json, :accept => :json
        index += length
      end
    end

    def get_datapoints
      time = @time_tracker.now_floored

      datapoints = []
      @registry.each do |name, metric|
        next if name.nil? || name.empty?
        name = name.to_s.gsub(/ +/, '_')

        case metric
        when Metriks::Meter
          datapoints << {
            :metric => "#{name}.count",
            :timestamp => time,
            :value => metric.count,
            :tags => @tags
          }
          datapoints << {
            :metric => "#{name}.mean_rate",
            :timestamp => time,
            :value => metric.mean_rate,
            :tags => @tags
          }
          datapoints << {
            :metric => "#{name}.m1",
            :timestamp => time,
            :value => metric.one_minute_rate,
            :tags => @tags
          }
          datapoints << {
            :metric => "#{name}.m5",
            :timestamp => time,
            :value => metric.five_minute_rate,
            :tags => @tags
          }
          datapoints << {
            :metric => "#{name}.m15",
            :timestamp => time,
            :value => metric.fifteen_minute_rate,
            :tags => @tags
          }
        when Metriks::Counter
          datapoints << {
            :metric => name,
            :timestamp => time,
            :value => metric.count,
            :tags => @tags
          }
        when Metriks::Gauge
          datapoints << {
            :metric => name,
            :timestamp => time,
            :value => metric.value,
            :tags => @tags
          }
        when Metriks::Histogram, Metriks::Timer, Metriks::UtilizationTimer
          datapoints << {
            :metric => "#{name}.count",
            :timestamp => time,
            :value => metric.count,
            :tags => @tags
          }
          if Metriks::UtilizationTimer === metric || Metriks::Timer === metric
            datapoints << {
              :metric => "#{name}.mean_rate",
              :timestamp => time,
              :value => metric.mean_rate,
              :tags => @tags
            }
            datapoints << {
              :metric => "#{name}.m1",
              :timestamp => time,
              :value => metric.one_minute_rate,
              :tags => @tags
            }
            datapoints << {
              :metric => "#{name}.m5",
              :timestamp => time,
              :value => metric.five_minute_rate,
              :tags => @tags
            }
            datapoints << {
              :metric => "#{name}.m15",
              :timestamp => time,
              :value => metric.fifteen_minute_rate,
              :tags => @tags
            }
          end
          snapshot = metric.snapshot
          datapoints << {
            :metric => "#{name}.median",
            :timestamp => time,
            :value => snapshot.median,
            :tags => @tags
          }

          @percentiles.each do |percentile|
            datapoints << {
              :metric => "#{name}.p#{(percentile * 100).to_i}",
              :timestamp => time,
              :value => snapshot.value(percentile),
              :tags => @tags
            }
          end
        end
      end
      info("Captured #{datapoints.size} metrics")
      datapoints
    end
  end
end
