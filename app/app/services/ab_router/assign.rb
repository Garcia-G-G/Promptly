require "zlib"

module AbRouter
  class Assign
    STICKY_TTL = 86_400 # 24 hours

    def self.call(experiment:, request_id:)
      new(experiment:, request_id:).call
    end

    def initialize(experiment:, request_id:)
      @experiment = experiment
      @request_id = request_id
    end

    def call
      variant = nil
      redis_hit = false

      begin
        Promptly::Redis.with do |redis|
          # 1. Check sticky assignment
          sticky_key = Promptly::Redis.key("exp", @experiment.id, "req", @request_id)
          existing = redis.get(sticky_key)

          if existing
            redis_hit = true
            variant = existing.to_sym
          else
            # 2. Canary gate
            if @experiment.canary_stage.present?
              bucket = Zlib.crc32("#{@experiment.id}:#{@request_id}") % 100
              if bucket >= @experiment.canary_stage
                redis.incr(Promptly::Redis.key("exp", @experiment.id, "not_in_canary"))
                instrument(variant: :not_in_canary, redis_hit: false)
                return :not_in_canary
              end
            end

            # 3. Deterministic split
            split_bucket = Zlib.crc32("split:#{@experiment.id}:#{@request_id}") % 100
            variant = split_bucket < @experiment.traffic_split ? :a : :b

            # 4. Sticky assignment (SETNX + TTL)
            redis.set(sticky_key, variant.to_s, ex: STICKY_TTL, nx: true)

            # 5. Increment counter
            redis.incr(Promptly::Redis.key("exp", @experiment.id, "variant", variant, "count"))
          end
        end
      rescue => e
        # Degraded mode: Redis unavailable, use deterministic hash only
        Rails.logger.warn("AbRouter Redis error: #{e.message}")
        variant = fallback_assign
      end

      instrument(variant: variant, redis_hit: redis_hit)
      variant
    end

    private

    def fallback_assign
      # Canary gate
      if @experiment.canary_stage.present?
        bucket = Zlib.crc32("#{@experiment.id}:#{@request_id}") % 100
        return :not_in_canary if bucket >= @experiment.canary_stage
      end

      # Deterministic split
      split_bucket = Zlib.crc32("split:#{@experiment.id}:#{@request_id}") % 100
      split_bucket < @experiment.traffic_split ? :a : :b
    end

    def instrument(variant:, redis_hit:)
      ActiveSupport::Notifications.instrument("ab_router.assign.promptly", {
        experiment_id: @experiment.id,
        request_id: @request_id,
        variant: variant,
        redis_hit: redis_hit
      })
    end
  end
end
