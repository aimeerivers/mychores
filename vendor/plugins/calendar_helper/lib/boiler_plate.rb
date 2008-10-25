require 'active_record'
require 'date'

module BoilerPlate # :nodoc:
  module Model # :nodoc:

    # I18n support for ActiveRecord.
    # Currently, all that it does is define a class variable
    #
    #   ActiveRecord::Base.date_format
    #
    # and redefines +write_attribute+ to convert string values to dates
    # according to this format.
    module I18n

      def self.included(base)
        base.class_eval do
          unless method_defined?(:write_attribute_with_date_cast)
            alias_method :write_attribute_without_date_cast, :write_attribute

            def write_attribute_with_date_cast(attr, value)
              if column_for_attribute(attr).class == :date
                value = cast_to_date(value)
              end
              write_attribute_without_date_cast(attr, value)
            end

            alias_method :write_attribute, :write_attribute_with_date_cast

            cattr_accessor :date_format
            ActiveRecord::Base.date_format = '%Y-%m-%d'
          end
        end
      end

      protected

      def cast_to_date(value)
        case value
        when String
          Date.strptime(value, ActiveRecord::Base.date_format) rescue nil ### FIXME rescue better
        when Date, Time
          value
        else
          raise ArgumentError, "Argument for cast_to_date must be a String, Date, or Time; was: #{value.inspect}" 
        end
      end

    end
  end
end
