module NagiosHerald
  module ConfigurationManager
    class BaseManager
      def initialize(config)
        @config = config
      end

      def get(section = nil, key = nil)
        return @config if section.nil?
        return @config[section] if key.nil?
        return @config.to_hash.fetch(section, {})[key]
      end
    end
  end
end
