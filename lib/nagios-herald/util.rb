module NagiosHerald
  module Util
    def self.load_env_from_file(path)
      File.readlines(path).each do |line|
        values = line.split("=")
        key = values[0]
        value = values[1, values.length - 1 ].map {|v| v.strip() }.join('=')
        ENV[key] = value
      end
    end

    def self.unescape_text(text)
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

    def self.underscore_to_camel_case(name)
      words = name.downcase.split('_')
      return words.map! {|w| w.capitalize}.join('')
    end

    # Load all the formatters
    def self.load_formatter(name, formatter_dir = nil)
      return if name.nil?
      formatter_dir = formatter_dir || File.join(File.dirname(__FILE__) , "formatters")
      formatter_path = File.expand_path(File.join(formatter_dir, name.downcase))
      begin
        require formatter_path
        formatter_class = "NagiosHerald::Formatter::#{underscore_to_camel_case(name)}"
        constantize(formatter_class)
      rescue LoadError
        puts "Exception encountered loading #{formatter_path}"
        return nil
      end
    end


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
