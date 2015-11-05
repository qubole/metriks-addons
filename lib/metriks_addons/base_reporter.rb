module MetriksAddons
  class BaseReporter
    def initialize(options = {})
      @logger       = options[:logger] || nil
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

    def log(level, msg)
      if !@logger.nil?
        @logger.send level, msg
      end
    end
  end
end
