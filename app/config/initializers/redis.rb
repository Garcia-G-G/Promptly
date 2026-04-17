module Promptly
  module Redis
    PREFIX = "promptly:ab:"
    POOL_SIZE = ENV.fetch("RAILS_MAX_THREADS", 5).to_i

    class << self
      def pool
        @pool ||= if Rails.env.test?
          require "mock_redis"
          @mock_instance = MockRedis.new
          ConnectionPool.new(size: POOL_SIZE, timeout: 2) { @mock_instance }
        else
          ConnectionPool.new(size: POOL_SIZE, timeout: 2) do
            ::Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
          end
        end
      end

      def with(&block)
        pool.with(&block)
      end

      def healthy?
        with { |r| r.ping == "PONG" }
      rescue
        false
      end

      def key(*parts)
        PREFIX + parts.join(":")
      end

      def reset_pool!
        @pool = nil
        @mock_instance = nil
      end
    end
  end
end
