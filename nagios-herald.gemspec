($LOAD_PATH << File.expand_path("../lib", __FILE__)).uniq!
require "nagios-herald/version"

Gem::Specification.new do |spec|
  spec.name        = 'nagios-herald'
  spec.summary     = "A project that aims to make it easy to provide context in Nagios alerts."
  spec.version     = NagiosHerald::VERSION
  spec.authors     = ['Ryan Frantz', 'Nassim Kammah']
  spec.email       = ['rfrantz@etsy.com', 'nkammah@etsy.com']
  spec.homepage    = "https://github.com/etsy/nagios-herald"
  spec.license     = "MIT"

  spec.files       = `git ls-files`.split("\n")
  spec.test_files  = Dir["tests/**/*_test.rb"]
  #spec.executables = ["draw_stack_bars", "dump_nagios_env.sh", "get_ganglia_graph", "get_graph", "notify-by-handler", "splunk_alert_frequency"]
  spec.executables = ["nagios-herald"]
  spec.required_ruby_version = '>=1.9.2'

  spec.add_runtime_dependency 'app_conf', '~> 0.4', '>= 0.4.2'
  spec.add_runtime_dependency 'choice', '~> 0.1', '>= 0.1.6'
  spec.add_runtime_dependency 'mail', '~> 2.5', '>= 2.5.4'
  spec.add_runtime_dependency 'ohai', ['>= 7.4.0', '< 8.0']
  spec.add_runtime_dependency 'chef', '>= 11.8.2'
  spec.add_runtime_dependency 'elasticsearch', '>= 1.0.2'

  spec.description = <<-DESCRIPTION_END
  A project that aims to make it easy to provide context in Nagios alerts.
  The project consists of a core notifier script that can be called with a formatter
  to tailor the content of the message sent to an operator.
DESCRIPTION_END

  spec.post_install_message = "Have fun and write your own formatters!"

end
