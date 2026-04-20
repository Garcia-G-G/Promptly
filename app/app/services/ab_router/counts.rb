module AbRouter
  class Counts
    def self.call(experiment:)
      a_count = 0
      b_count = 0
      not_in_canary = 0

      begin
        Promptly::Redis.with do |redis|
          a_count = redis.get(Promptly::Redis.key("exp", experiment.id, "variant", "a", "count")).to_i
          b_count = redis.get(Promptly::Redis.key("exp", experiment.id, "variant", "b", "count")).to_i
          not_in_canary = redis.get(Promptly::Redis.key("exp", experiment.id, "not_in_canary")).to_i
        end
      rescue => e
        Rails.logger.warn("AbRouter::Counts Redis error: #{e.message}")
      end

      { a: a_count, b: b_count, not_in_canary: not_in_canary }
    end
  end
end
