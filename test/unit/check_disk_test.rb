

require 'nagios-herald'
require 'nagios-herald/formatters/check_disk'
require 'test/unit'
require 'ostruct'
require 'assertions'

class GetPartitionDataTest < Test::Unit::TestCase

  def setup
    @options = OpenStruct.new
    @options.config_file = File.expand_path(File.dirname(__FILE__) + '/../../etc/config.yml.example')
    @options.pager_mode = false
    @options.noemail = false
    @options.debug = false
    @options.nagiosurl = 'http://test/nagios/'

    @cfgmgr = NagiosHerald::ConfigurationManager.get_configuration_manager('simple', {})
    @formatter = NagiosHerald::Formatter::CheckDisk.new(@cfgmgr, @options)

  end

  def i_test_empty_input
    output = @formatter.get_partitions_data("")
    assert_equal([], output)
  end

  def test_single_entry
    input = 'DISK CRITICAL - free space: '\
            '/ 7051 MB (18% inode=60%);'\
            '/data 16733467 MB (27% inode=99%);|'\
            '/=31220MB;36287;2015;0;40319 '\
            '/dev/shm=81MB;2236;124;0;2485 '\
            '/data=44240486MB;54876558;3048697;0;60973954'

    expected = [
      {"partition"=>"/", "free_unit"=>"7051 MB", "free_percent"=>"18"},
      {"partition"=>"/data", "free_unit"=>"16733467 MB", "free_percent"=>"27"},
    ]

    actual = @formatter.get_partitions_data(input)

    assert_equal(expected, actual)
  end

  def test_multiple_entries_simple_format
    input = 'DISK CRITICAL - free space: '\
            '/ 7002 MB (18% inode=60%);'\
            '/data 16273093 MB (26% inode=99%):'

    expected = [
      {"partition"=>"/", "free_unit"=>"7002 MB", "free_percent"=>"18"},
      {"partition"=>"/data", "free_unit"=>"16273093 MB", "free_percent"=>"26"},
    ]

    actual = @formatter.get_partitions_data(input)

    assert_equal(expected, actual)
  end

  def test_multiple_entries_full_format
    input = 'DISK CRITICAL - free space: '\
            '/ 7051 MB (18% inode=60%);'\
            '/data 16733467 MB (27% inode=99%);|'\
            '/=31220MB;36287;2015;0;40319 '\
            '/dev/shm=81MB;2236;124;0;2485 '\
            '/data=44240486MB;54876558;3048697;0;60973954'

    expected = [
      {"partition"=>"/", "free_unit"=>"7051 MB", "free_percent"=>"18"},
      {"partition"=>"/data", "free_unit"=>"16733467 MB", "free_percent"=>"27"},
    ]

    actual = @formatter.get_partitions_data(input)

    assert_equal(expected, actual)
  end
end