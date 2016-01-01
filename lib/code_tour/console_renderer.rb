require 'colorize'

module CodeTour
  module ConsoleRenderer

    def render_file_static(f)
      f.name << "\n\n" <<
      f.lines.map do |l|
        "#{l.new_number.to_s.center(5)} | #{l.content}"
      end.join("\n")
    end

    def render_file_diff(f)
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
        ("#{l.old_number.to_s.center(5)} | " <<
        "#{l.new_number.to_s.center(5)} | #{l.content}").colorize(color)
      end.join("\n")
    end

    def render(blocks)
      blocks.map do |b|
        b.content << "\n----\n\n" <<
          b.sample.map do |f|
            case f
              when CodeTour::CodeSample::SampleFileStatic
                render_file_static(f)
              else
                render_file_diff(f)
            end
          end.join("\n\n") << "\n----\n\n"
      end.join("\n\n")
    end
  end
end
