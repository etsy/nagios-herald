($LOAD_PATH << File.expand_path("../lib", __FILE__)).uniq!
require "nagios-herald/version"

Gem::Specification.new do |spec|
  spec.name        = 'nagios-herald'
  spec.summary     = "A set of scripts to improve Nagios email alerts."
  spec.version     = NagiosHerald::VERSION
  spec.authors     = ['Ryan Frantz', 'Nassim Kammah']
  spec.email       = ['rfrantz@etsy.com', 'nkammah@etsy.com']
  spec.homepage    = "https://github.etsycorp.com/Sysops/nagios-email-handler"
  spec.license     = "GPL"

  spec.files       = `git ls-files`.split("\n")
  spec.test_files  = Dir["tests/**/*_test.rb"]
  spec.executables = ["draw_stack_bars", "dump_nagios_env.sh", "get_ganglia_graph", "get_graph", "notify-by-handler", "send_html_email", "splunk_alert_frequency"]
  spec.required_ruby_version = '>=1.9.2'

  spec.add_dependency 'app_conf'
  spec.add_dependency 'choice'
  spec.add_dependency 'mail'

  spec.description = <<-END
  A set of scripts to improve Nagios email alerts. The project consists of a core notifier script
  that can be called with a specific format helper to add context to email alerts sent from Nagios.
END

  spec.post_install_message = <<-END
Have fun and write your own formatters!

END


end