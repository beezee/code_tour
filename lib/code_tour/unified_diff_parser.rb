module CodeTour
  class UnifiedDiffParser
    LineCount = Struct.new(:old, :new) do

      def incr_new
        LineCount.new(old, new+1)
      end

      def incr_old
        LineCount.new(old+1, new)
      end

      def incr_both
        LineCount.new(old+1, new+1)
      end
    end

    LineCountWithLines = Struct.new(:count, :lines)

    LINE_MATCHERS = {
      chunk_header: /^(@@ [\-\+\d\,\s]+ @@.*$)/,
      added: /^\+/,
      removed: /^\-/
    }

    def lcl_constructors
      {
        added: [
          :incr_new,
          CodeTour::CodeSample::AddedLine,
          ->(lcl) { nil }, # old count
          ->(lcl) { lcl.count.new } # new count
        ],
        removed: [
          :incr_old,
          CodeTour::CodeSample::RemovedLine,
          ->(lcl) { lcl.count.old }, # old count
          ->(lcl) { nil } # new count
        ],
        unchanged: [
          :incr_both,
          CodeTour::CodeSample::SampleLine,
          ->(lcl) { lcl.count.old }, # old count
          ->(lcl) { lcl.count.new } # new count
        ]
      }
    end

    def initialize(content)
      @content = content
    end

    def chunks(lines)
      lines.split(LINE_MATCHERS[:chunk_header])
        .drop_while {|c| !(LINE_MATCHERS[:chunk_header] === c) }
    end

    # @@ -3,7 +3,6 @@ => LineCount
    def parse_chunk_header(header)
      m = /\-([\d]+).*\+([\d]+)/.match(header)
      unless m.kind_of?(MatchData) && m.size >= 2
        raise "Invalid chunk header found #{header}"
      end
      LineCount.new(m[1].to_i, m[2] ? m[2].to_i : m[1].to_i)
    end

    def lines_with_counts(header)
      LineCountWithLines.new(parse_chunk_header(header), [])
    end

    def add_line_to_lcl(type, lcl, line)
      lcl_ct = lcl_constructors[type]
      unless (lcl_ct.kind_of?(Array) && lcl_ct.size == 4)
        raise "Invalid type #{type} provided for new line in diff"
      end
      LineCountWithLines.new(
        lcl.count.send(lcl_ct[0]),
        lcl.lines +
          [lcl_ct[1].new(lcl_ct[2].(lcl), lcl_ct[3].(lcl), line)])
    end

    def parse_line_with_count(lcl, line)
      case line
      when LINE_MATCHERS[:chunk_header]
        raise 'Cannot parse chunk header inside chunk'
      when LINE_MATCHERS[:added]
        add_line_to_lcl(:added, lcl, line)
      when LINE_MATCHERS[:removed]
        add_line_to_lcl(:removed, lcl, line)
      else
        add_line_to_lcl(:unchanged, lcl, line)
      end
    end

    def parse_lines(lines)
      chunks(lines)
        .each_slice(2)
        .flat_map do |(header, chunk_lines)|
          [CodeTour::CodeSample::ChunkHeaderLine.new(nil, nil, header)] +
          chunk_lines
            .split("\n")[1..-1]
            .inject(lines_with_counts(header)) do |ct, l|
              parse_line_with_count(ct, l)
            end.lines
        end
    end

    def parse
      @content.dup
        .partition("diff")[1..-1].join("")
        .split(/^diff \-\-git a([^\s]+).*$/)
        .drop_while(&:empty?)
        .each_slice(2)
        .map do |(name, lines)|
          CodeTour::CodeSample::SampleFile.new(
            name, parse_lines(lines))
        end
    end
  end
end
