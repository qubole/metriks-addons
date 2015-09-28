require 'metriks/time_tracker'
require 'logger'
require 'aws'

module Metriks
  class CloudWatchReporter
    attr_accessor :prefix, :source, :cw, :tags, :logger

    def initialize(access_key, secret_key, namespace, tags, options = {})
      @cw = AWS::CloudWatch.new(:access_key_id => access_key, :secret_access_key => secret_key)
      @namespace = namespace
      @dimensions = get_dimensions(tags)

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

    def log(level, msg)
      if !@logger.nil?
        @logger.send level, msg
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
          log "debug", "Flushing metrics"
          submit get_datapoints
        end
      rescue Exception => ex
        log "error",ex.message
        @on_error[ex] rescue nil
      end
    end

    def submit(datapoints)
      return if datapoints.empty?
			datapoints.each do |datapoint|
				@cw.put_metric_data({:namespace => @namespace, 
															:metric_data => [datapoint]
														})
			end	
      log "info", "Sent #{datapoints.size} metrics to CloudWatch"
    end

    def get_datapoints
      time = @time_tracker.now_floored

      datapoints = []
      @registry.each do |name, metric|
        next if name.nil? || name.empty?
        name = name.to_s.gsub(/ +/, '_')
        if @prefix
          name = "#{@prefix}.#{name}"
        end

        case metric
        when Metriks::Meter
          datapoints |= create_datapoints name, metric, time, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate
          ]
        when Metriks::Counter
          datapoints |= create_datapoints name, metric, time, [
            :count
          ]
        when Metriks::Gauge
          datapoints |= create_datapoints name, metric, time, [
            :value
          ]
        when Metriks::UtilizationTimer
          datapoints |= create_datapoints name, metric, time, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate,
            :min, :max, :mean, :stddev,
            :one_minute_utilization, :five_minute_utilization,
            :fifteen_minute_utilization, :mean_utilization,
          ], [
            :median, :get_95th_percentile
          ]

          when Metriks::Timer
          datapoints |= create_datapoints name, metric, time, [
            :count, :one_minute_rate, :five_minute_rate,
            :fifteen_minute_rate, :mean_rate,
            :min, :max, :mean, :stddev
          ], [
            :median, :get_95th_percentile
          ]
          when Metriks::Histogram
          datapoints |= create_datapoints name, metric, time, [
            :count, :min, :max, :mean, :stddev
          ], [
            :median, :get_95th_percentile
          ]
        end
      end
      datapoints
    end

    def create_datapoints(base_name, metric, time, keys, snapshot_keys = [])
      datapoints = []
      
      keys.flatten.each do |key|
        name = key.to_s.gsub(/^get_/, '')
        datapoints << {
          :metric_name => "#{base_name}.#{name}",
          :timestamp => time,
          :value => metric.send(key),
          :dimensions => @dimensions
        }
      end

      unless snapshot_keys.empty?
        snapshot = metric.snapshot
        snapshot_keys.flatten.each do |key|
          name = key.to_s.gsub(/^get_/, '')
          datapoints << {
            :metric_name => "#{base_name}.#{name}",
            :timestamp => time,
            :value => snapshot.send(key),
            :dimensions => @dimensions
          }
        end
      end
      datapoints
    end
    
    def get_dimensions(tags)
    	dimensions =[]
	    tags.each do |name, value|
    		dimensions << {
    			:name => "#{name}",
    			:value => value
    		}
    	end
	    dimensions
    end
  end
end
