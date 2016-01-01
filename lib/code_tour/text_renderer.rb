require 'colorize'

module CodeTour
  module TextRenderer

    def render_file(f)
      f.name << "\n\n" <<
      f.lines.map do |l|
        color = case l
          when CodeTour::CodeSample::AddedLine
            :green
          when CodeTour::CodeSample::RemovedLine
            :red
          else
            :black
          end
        "#{l.old_number.to_s.center(5)} | ".colorize(color) <<
        "#{l.new_number.to_s.center(5)} | #{l.content}".colorize(color)
      end.join("\n")
    end

    def render(blocks)
      blocks.map do |b|
        b.content << "\n----\n\n" <<
          b.sample.map {|f| render_file(f)}.join("\n\n")
      end.join("\n")
    end
  end
end
