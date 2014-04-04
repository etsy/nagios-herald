module NagiosHerald
  module ConfigurationManager

    def self.get_configuration_manager(type, options)
      return nil unless ['simple', 'chef'].include? type
      require File.expand_path(File.join(File.dirname(__FILE__), 'configuration_manager', type))
      klass = NagiosHerald::Util::constantize("NagiosHerald::ConfigurationManager::#{type.capitalize}Manager")
      return klass.new(options)
    end

  end
end
