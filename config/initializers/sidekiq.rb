Sidekiq.default_worker_options = { 'backtrace' => true, retry: false }

# Define queues here instead of config/sidekiq.rb.
# This way, this defines default queues for all your_platform applications.
#
Sidekiq.options[:queues] = ['default', 'mailgate', 'mailers']

# https://github.com/brainopia/sidekiq-limit_fetch
#
Sidekiq.options[:limits] = {default: 25, mailgate: 1}

# http://stackoverflow.com/questions/14825565/sidekiq-deploy-to-multiple-environments
# 
Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://localhost:6379/0', namespace: "#{::STAGE}_sidekiq" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://localhost:6379/0', namespace: "#{::STAGE}_sidekiq" }
end 