require 'rake/testtask'

task :default => 'test:integration'

# Tests
namespace :test do

  desc 'Run nagios-herald unit tests'
  Rake::TestTask.new :unit do |t|
    t.libs << 'lib'
    t.libs << 'test'
    t.pattern = 'test/unit/*_test.rb'
    t.verbose = false
  end


  desc 'Run nagios-herald integration tests'
  Rake::TestTask.new :integration do |t|
    t.libs << 'lib'
    t.libs << 'test'
    t.pattern = 'test/integration/*_test.rb'
    t.verbose = false
  end
end
