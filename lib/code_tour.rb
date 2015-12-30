require "code_tour/version"
require "code_tour/git"

module CodeTour
  module CodeSample
    SampleLine = Struct.new(:number, :content)
    SampleFile = Struct.new(:name, :lines) do
      def valid?
        name.kind_of?(String) &&
          lines.kind_of?(Array) &&
          lines.all? {|l| l.kind_of?(SampleLine)}
      end
    end

    class RemovedLine < SampleLine
    end

    class AddedLine < SampleLine
    end
  end

  class Definition
    Block = Struct.new(:sample, :content)

    def initialize
      @blocks = []
    end

    def version_control_integration(i)
      unless i.respond_to?(:instance_methods) &&
            i.instance_methods(false).include?(:validate_code_sample!) &&
            i.instance_methods(false).include?(:format_sample)
        raise "#{i} is not a valid "+
              "version control integration"
      end
      self.singleton_class.send(:include, i)
    end

    def content_formatter(f)
      unless f.respond_to?(:instance_methods) &&
            f.instance_methods(false).include?(:format_content)
        raise "#{f} is not a valid content formatter"
      end
      self.singleton_class.send(:include, f)
    end

    def renderer(r)
      unless r.respond_to?(:instance_methods) &&
            r.instance_methods(false).include?(:render)
        raise "#{r} is not a valid renderer"
      end
      self.singleton_class.send(:include, r)
    end

    def validated_formatted_sample!(sample)
      format_sample(sample).tap do |formatted|
        unless formatted.kind_of?(Array) &&
                  formatted.all? do |f|
                    f.kind_of?(CodeSample::SampleFile) &&
                    f.valid?
                  end
          raise "Invalid sample output, make sure "+
                  "version_control_integration#format_sample "+
                  "returns array of valid SampleFile instances"
        end
      end
    end

    def formatted_blocks
      @blocks.map do |b|
        Block.new(validated_formatted_sample!(b.sample),
                  format_content(b.content))
      end
    end

    def render_blocks
      render(formatted_blocks)
    end

    private
    def block(code_sample, &block)
      validate_code_sample!(code_sample)
      @blocks.push(Block.new(code_sample, block.call))
    end
  end

  def self.define(&block)
    Definition.new.tap do |i|
      i.instance_eval(&block)
    end
  end
end
