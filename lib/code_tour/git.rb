require 'code_tour/unified_diff_parser'

module CodeTour
  module Git
    Show = Struct.new(:commit)
    Diff1 = Struct.new(:commit)
    Diff2 = Struct.new(:from_commit, :to_commit)
    FileDiff = Struct.new(:from_commit, :to_commit, :files)
    StaticFiles = Struct.new(:commit, :files)

    INVALID_SAMPLE = "Invalid code sample specified for Git integration"

    def validate_code_sample!(code_sample)
      unless [Show, Diff1, Diff2, FileDiff, StaticFiles]
                .include?(code_sample.class)
        raise INVALID_SAMPLE
      end
    end

    def git_cat_command(c, f)
     "git cat-file -p $(git ls-tree #{c} #{f} | cut -d " +
     '" " -f 3 | cut -f 1)'
    end

    def git_cat(sample)
      sample.files.map do |f|
        CodeSample::SampleFile.new(f,
          `#{git_cat_command(sample.commit, f)}`
            .split("\n").each_with_index.map do |l, i|
              CodeSample::SampleLine.new(i+1, l)
            end)
      end
    end

    def parse_diff(diff)
      UnifiedDiffParser.new(diff).parse
    end

    def format_sample(s)
      case s
      when Show
        parse_diff(
          `git show #{s.commit}`)
      when Diff1
        parse_diff(
          `git diff #{s.commit}`)
      when Diff2
        parse_diff(
          `git diff #{s.from_commit} #{s.to_commit}`)
      when FileDiff
        parse_diff(
          `git diff #{s.from_commit} #{s.to_commit} #{s.files.join(" ")}`)
      when StaticFiles
        git_cat(s)
      else
        raise INVALID_SAMPLE
      end
    end

    def diff(from, to=nil, files=nil)
      (files.kind_of?(Array) && !files.empty?) ?
        FileDiff.new(from, to, files) :
        (to.nil? ?
          Diff1.new(from) :
          Diff2.new(from, to))
    end

    def static(commit, files)
      StaticFiles.new(commit, files)
    end

    def show(commit)
      Show.new(commit)
    end
  end
end
