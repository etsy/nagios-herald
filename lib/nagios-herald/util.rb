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

    # TODO: replace constantize with code that loads classes automatically
    # tries to find a constant with the name specified in the argument string
    # (from Ruby on Rails?)
    # this is used to return an object of the specified name?
    def self.constantize(camel_cased_word)
      names = camel_cased_word.split('::')
      names.shift if names.empty? || names.first.empty?

      names.inject(Object) do |constant, name|
        if constant == Object
          constant.const_get(name)
        else
          candidate = constant.const_get(name)
          next candidate if constant.const_defined?(name, false)
          next candidate unless Object.const_defined?(name)

          # Go down the ancestors to check it it's owned
          # directly before we reach Object or the end of ancestors.
          constant = constant.ancestors.inject do |const, ancestor|
            break const    if ancestor == Object
            break ancestor if ancestor.const_defined?(name, false)
            const
          end

          # owner is in Object, so raise
          constant.const_get(name, false)
        end
      end
    end

  end
end
