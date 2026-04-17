module Experiments
  class BayesianSignificance
    PRIOR_ALPHA = 1.0
    PRIOR_BETA = 1.0
    SIGNIFICANCE_THRESHOLD = 0.95
    EXPECTED_LOSS_EPSILON = 0.005
    MONTE_CARLO_SAMPLES = 50_000

    def self.call(experiment:)
      new(experiment).call
    end

    def initialize(experiment)
      @experiment = experiment
    end

    def call
      return nil unless @experiment.running?

      stats_a = variant_stats("a")
      stats_b = variant_stats("b")

      return nil if stats_a[:n] < 30 || stats_b[:n] < 30

      alpha_a = PRIOR_ALPHA + stats_a[:successes]
      beta_a = PRIOR_BETA + stats_a[:failures]
      alpha_b = PRIOR_ALPHA + stats_b[:successes]
      beta_b = PRIOR_BETA + stats_b[:failures]

      prob_b_wins = monte_carlo_comparison(alpha_a, beta_a, alpha_b, beta_b)
      prob_a_wins = 1.0 - prob_b_wins

      loss_a = expected_loss(alpha_b, beta_b, alpha_a, beta_a)
      loss_b = expected_loss(alpha_a, beta_a, alpha_b, beta_b)

      winner = determine_winner(prob_a_wins, prob_b_wins, loss_a, loss_b)

      {
        prob_a_wins: prob_a_wins.round(4),
        prob_b_wins: prob_b_wins.round(4),
        expected_loss_a: loss_a.round(6),
        expected_loss_b: loss_b.round(6),
        significance: [ prob_a_wins, prob_b_wins ].max.round(4),
        stats_a: stats_a,
        stats_b: stats_b,
        winner: winner
      }
    end

    private

    def variant_stats(variant)
      scores = @experiment.experiment_results.where(variant: variant).where.not(score: nil).pluck(:score)
      n = scores.size
      return { n: 0, mean: 0, successes: 0, failures: 0 } if n == 0

      successes = scores.count { |s| s >= 0.5 }
      { n: n, mean: (scores.sum / n.to_f).round(4), successes: successes, failures: n - successes }
    end

    def monte_carlo_comparison(alpha_a, beta_a, alpha_b, beta_b)
      rng = Random.new(42)
      wins_b = 0
      MONTE_CARLO_SAMPLES.times do
        wins_b += 1 if beta_sample(rng, alpha_b, beta_b) > beta_sample(rng, alpha_a, beta_a)
      end
      wins_b.to_f / MONTE_CARLO_SAMPLES
    end

    def expected_loss(alpha_w, beta_w, alpha_l, beta_l)
      rng = Random.new(43)
      total = 0.0
      MONTE_CARLO_SAMPLES.times do
        total += [ beta_sample(rng, alpha_w, beta_w) - beta_sample(rng, alpha_l, beta_l), 0 ].max
      end
      total / MONTE_CARLO_SAMPLES
    end

    def beta_sample(rng, alpha, beta)
      x = gamma_sample(rng, alpha)
      y = gamma_sample(rng, beta)
      x / (x + y)
    end

    # Marsaglia-Tsang method for Gamma(alpha) when alpha >= 1
    # For alpha < 1, uses Gamma(alpha+1) * U^(1/alpha) trick
    def gamma_sample(rng, alpha)
      if alpha < 1.0
        return gamma_sample(rng, alpha + 1.0) * (rng.rand ** (1.0 / alpha))
      end

      d = alpha - 1.0 / 3.0
      c = 1.0 / Math.sqrt(9.0 * d)

      loop do
        x = normal_sample(rng)
        v = (1.0 + c * x) ** 3
        next if v <= 0

        u = rng.rand
        if u < 1.0 - 0.0331 * (x ** 2) ** 2
          return d * v
        end
        if Math.log(u) < 0.5 * x ** 2 + d * (1.0 - v + Math.log(v))
          return d * v
        end
      end
    end

    def normal_sample(rng)
      u1 = rng.rand
      u2 = rng.rand
      Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math::PI * u2)
    end

    def determine_winner(prob_a, prob_b, loss_a, loss_b)
      if prob_a > SIGNIFICANCE_THRESHOLD && loss_a < EXPECTED_LOSS_EPSILON
        :a
      elsif prob_b > SIGNIFICANCE_THRESHOLD && loss_b < EXPECTED_LOSS_EPSILON
        :b
      end
    end
  end
end
