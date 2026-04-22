class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # In development we enable strict_loading_by_default on the environment
  # (see config/environments/development.rb). :n_plus_one_only only raises
  # when the same association is loaded repeatedly in a loop, which is
  # the shape we care about — one-off missed preloads stay as warnings.
  self.strict_loading_mode = :n_plus_one_only if Rails.env.development?
end
