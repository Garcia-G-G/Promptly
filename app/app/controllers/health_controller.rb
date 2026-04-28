class HealthController < ActionController::API
  # Extended health check used by load balancers and uptime probes.
  # Unlike /up (rails/health), this verifies every critical dependency
  # — DB, Redis, and pending migrations — and returns 503 if any fail.
  def show
    checks = {
      database:   check_database,
      redis:      check_redis,
      migrations: check_migrations
    }

    healthy = checks.values.all? { |c| c[:status] == "ok" }

    render json: {
      status: healthy ? "healthy" : "unhealthy",
      checks: checks
    }, status: healthy ? :ok : :service_unavailable
  end

  private

  def check_database
    ActiveRecord::Base.connection.execute("SELECT 1")
    { status: "ok" }
  rescue => e
    { status: "error", message: e.message.truncate(200) }
  end

  def check_redis
    Promptly::Redis.healthy? ? { status: "ok" } : { status: "error", message: "redis did not return PONG" }
  rescue => e
    { status: "error", message: e.message.truncate(200) }
  end

  def check_migrations
    ActiveRecord::Migration.check_all_pending!
    { status: "ok" }
  rescue => e
    { status: "error", message: e.message.truncate(200) }
  end
end
