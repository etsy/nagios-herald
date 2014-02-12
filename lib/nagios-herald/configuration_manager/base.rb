module AbstractInterface

  class InterfaceNotImplementedError < NoMethodError
  end

  def self.included(klass)
    klass.send(:include, AbstractInterface::Methods)
    klass.send(:extend, AbstractInterface::Methods)
    klass.send(:extend, AbstractInterface::ClassMethods)
  end

  module Methods

    def api_not_implemented(klass, method_name = nil)
      if method_name.nil?
        caller.first.match(/in \`(.+)\'/)
        method_name = $1
      end
      raise AbstractInterface::InterfaceNotImplementedError.new("#{klass.class.name} needs to implement '#{method_name}' for interface #{self.name}!")
    end

  end

  module ClassMethods

    def needs_implementation(name, *args)
      self.class_eval do
        define_method(name) do |*args|
          ConfigurationManager.api_not_implemented(self, name)
        end
      end
    end

  end

end

module NagiosHerald
  module ConfigurationManager
    class AbstractConfigurationManager
      include AbstractInterface

      needs_implementation :get_cluster_name_for_host, :host

      def initialize(config)
        @config = config
      end

      def get(section = nil, key = nil)
        return @config if section.nil?
        return @config[section] if key.nil?
        return @config[section][key]
      end
    end
  end
end