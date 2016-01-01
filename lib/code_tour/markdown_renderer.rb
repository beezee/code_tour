require 'erb'
require 'redcarpet'

module CodeTour
  module MarkdownRenderer
    Context = Struct.new(:rendered_blocks)
    SampleLine = Struct.new(:line, :static) do

      def old_number
        line.old_number || '&nbsp;'
      end

      def new_number
        line.new_number || '&nbsp;'
      end

      def formatted_content
        "<pre class='prettyprint'>#{line.content}</pre>"
      end

      def line_numbers
        (static ?
          line.new_number :
          ("<div class='row'>"+
            "<div class='one-half column'>#{old_number}</div>"+
            "<div class='one-half column'>#{new_number}</div>"+
           "</div>"))
      end

      def render_chunk_header_line
        "<div class='at-linenums'>#{line.content}</div>"
      end

      def render_unchanged_line
        "<div class='unchanged'>#{formatted_content}</div>"
      end

      def render_added_line
        "<div class='add'>#{formatted_content}</div>"
      end

      def render_removed_line
        "<div class='delete'>#{formatted_content}</div>"
      end

      def content
        case line
        when CodeTour::CodeSample::ChunkHeaderLine
          render_chunk_header_line
        when CodeTour::CodeSample::AddedLine
          render_added_line
        when CodeTour::CodeSample::RemovedLine
          render_removed_line
        when CodeTour::CodeSample::SampleLine
          render_unchanged_line
        else
          raise "Invalid line passed to MarkdownRenderer::SampleLine"
        end
      end
    end

    def template
      File.read(
        @template || File.expand_path('../template.erb', __FILE__))
    end

    def markdown
      @markdown ||
        Redcarpet::Markdown.new(Redcarpet::Render::HTML.new,
          autolink: true,
          disable_indented_code_blocks: true)
    end

    def markdown_renderer(renderer)
      unless renderer.kind_of?(Redcarpet::Markdown)
        raise "Invalid markdown renderer provided"
      end
      @markdown = Redcarpet::Markdown.new(renderer)
    end

    def template_path(path)
      unless File.exists?(path)
        raise "Template file #{path} does not exist"
      end
      @template = path
    end

    def render(blocks)
      prepared = blocks.map do |b|
        b.class.new(
          b.sample.map do |f|
            f.class.new(
              f.name,
              f.lines.map do |l|
                SampleLine.new(l,
                  f.kind_of?(CodeTour::CodeSample::SampleFileStatic))
              end)
          end,
          markdown.render(b.content.dup))
      end
      bd = Context.new(prepared).instance_eval { binding }
      ERB.new(template).result(bd)
    end
  end
end
