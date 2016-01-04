require "code_tour/version"
require "code_tour/git"
require "code_tour/console_renderer"
require "code_tour/markdown_renderer"

module CodeTour
  module CodeSample
    SampleFile = Struct.new(:name, :lines) do
      def valid?
        name.kind_of?(String) &&
          lines.kind_of?(Array) &&
          lines.all? {|l| l.kind_of?(SampleLine)}
      end
    end

    class SampleFileStatic < SampleFile
    end

    SampleLine = Struct.new(:old_number, :new_number, :content)

    class ChunkHeaderLine < SampleLine
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

    def renderer(r)
      unless r.respond_to?(:instance_methods) &&
            r.instance_methods(false).include?(:render)
        raise "#{r} is not a valid renderer"
      end
      self.singleton_class.send(:include, r)
    end

    def validated_formatted_sample!(sample)
      if sample.kind_of?(Array) && sample.empty?
        sample
      else
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
    end

    def formatted_blocks
      @blocks
        .dup
        .map do |b|
          Block.new(validated_formatted_sample!(b.sample.dup),
                    b.content.dup)
        end
    end

    def render_blocks
      render(formatted_blocks)
    end

    private
    def block(code_sample = nil)
      unless code_sample.nil?
        validate_code_sample!(code_sample)
      end
      @blocks.push(Block.new(code_sample || [], yield))
    end
  end

  def self.define(&block)
    Definition.new.tap do |i|
      i.instance_eval(&block)
    end
  end
end
