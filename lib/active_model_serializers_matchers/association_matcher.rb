module ActiveModelSerializersMatchers
  class AssociationMatcher

    attr_reader :root, :type, :checks
    attr_reader :actual

    def initialize(root:, type:)
      @root = root
      @type = type
      @checks = [AssociationCheck.new(self, type)]
    end

    def matches?(actual)
      @actual = actual.is_a?(Class) ? actual : actual.class
      checks.all?(&:pass?)
    end

    def description
      checks.map(&:description).join(' ')
    end

    def failure_message
      checks.find(&:fail?).failure_message
    end

    def root_association
      associations[root]
    end

    def as(key)
      checks << KeyCheck.new(self, key)
      self
    end

    def serialized_with(serializer)
      checks << SerializerCheck.new(self, serializer)
      self
    end

    private

    def associations
      actual._associations
    end

    class AssociationCheck

      attr_reader :matcher, :type

      def initialize(matcher, type)
        @matcher = matcher
        @type = type
      end

      def pass?
        return false if matcher.root_association.nil?
        matcher.root_association.superclass == association_type
      end

      def fail?
        !pass?
      end

      def description
        "#{ association_string } #{ matcher.root.inspect }"
      end

      def failure_message
        "expected #{ matcher.actual } to define a '#{ type } #{ matcher.root.inspect }' association"
      end

      private

      def association_type
        case type
        when :has_one
          ActiveModel::Serializer::Associations::HasOne
        when :has_many
          ActiveModel::Serializer::Associations::HasMany
        else
          raise ArgumentError, "'#{type}' is an invalid association type."
        end
      end

      def association_string
        case type
        when :has_one
          'have one'
        when :has_many
          'have many'
        end
      end
    end

    class KeyCheck

      attr_reader :matcher, :key

      def initialize(matcher, key)
        @matcher = matcher
        @key = key
      end

      def pass?
        matcher.root_association.options[:key] == key
      end

      def fail?
        !pass?
      end

      def description
        "as #{ key.inspect }"
      end

      def failure_message
        "expected #{ matcher.actual } '#{ matcher.type } #{ matcher.root.inspect }' association to explicitly have key #{ key.inspect } but instead has none"
      end
    end

    class SerializerCheck

      attr_reader :matcher, :serializer

      def initialize(matcher, serializer)
        @matcher = matcher
        @serializer = serializer
      end

      def pass?
        false
      end

      def fail?
        !pass?
      end

      def failure_message
        "expected #{ matcher.actual } '#{ matcher.type } #{ matcher.root.inspect }' association to explicitly have serializer #{ serializer } but instead has none"
      end
    end
  end
end
