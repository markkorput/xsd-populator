
module DataProvider

  module Base

    def self.included(base)
      base.class_eval do
        include InstanceMethods
        extend ClassMethods
      end
    end

    module ClassMethods
      def provider *args
        add_provider(*args)
      end

      def data_provider_definitions
        ((@data_provider || {})[:provider_args] || [])
      end

      def has_provider?(identifier)
        !data_provider_definitions.find{|args| args.first == identifier}.nil?
      end

      private

      def add_provider(*args)
        @data_provider ||= {}
        @data_provider[:provider_args] ||= []
        @data_provider[:provider_args] << args
      end

    end # module ClassMethods

    module InstanceMethods

      def initialize(data = {})
        @data = (data.is_a?(Hash) ? data : {})
      end

      def has_provider?(identifier)
        self.class.has_provider?(identifier)
      end

    end # module InstanceMethods

  end # module Base

end # module DataProvider