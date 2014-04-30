module NagiosHerald
  module Util

    # TODO: add methods for handling HTTP(s) requests so we can control timeouts

    def unescape_text(text)
      return text.gsub("\\n", "\n").gsub("\\t", "\t")
    end

    def self.get_script_path(script_name)
      current_dir = File.dirname(__FILE__)
      rel_path = File.join(current_dir, '..', '..', 'bin', script_name)
      return File.expand_path(rel_path)
    end

    def self.load_helper(name)
      helper_path = File.expand_path(File.join(File.dirname(__FILE__), 'helpers', name))
      $stderr.puts "Helper '#{name}' not found" unless File.exist?(helper_path + ".rb")
      begin
        require helper_path
        return true
      rescue LoadError
        $stderr.puts "Exception encountered loading '#{name}' helper library!"
        return false
      end
    end

    def get_nagios_var(name)
      value = ENV[name]
    end

    def self.underscore_to_camel_case(name)
      words = name.downcase.split('_')
      return words.map! {|w| w.capitalize}.join('')
    end

  end
end
