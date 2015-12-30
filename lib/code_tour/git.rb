module CodeTour
  module Git
    Diff = Struct.new(:from_commit, :to_commit)
    FileDiff = Struct.new(:from_commit, :to_commit, :files)
    StaticFiles = Struct.new(:commit, :files)

    INVALID_SAMPLE = "Invalid code sample specified for Git integration"

    def validate_code_sample!(code_sample)
      unless [Diff, FileDiff, StaticFiles].include?(code_sample.class)
        raise INVALID_SAMPLE
      end
    end

    def git_cat(sample)
      sample.files.map do |f|
        [f, `git cat-file -p $(git ls-tree #{sample.commit}
            #{f} | cut -d " " -f 3 | cut -f 1)`]
      end
    end

    def format_sample(sample)
      git_output =
        case sample.class
        when Diff
          `git diff #{sample.from_commit} #{sample.to_commit}`
        when FileDiff
          `git diff #{sample.from_commit} #{sample.to_commit}
            #{files.join(" ")}`
        when StaticFiles
          git_cat(sample)
        else
          raise INVALID_SAMPLE
        end
    end

    def diff(from, to, files=nil)
      (files.kind_of?(Array) && !files.empty?) ?
        FileDiff.new(from, to, files) :
        Diff.new(from, to)
    end

    def static(commit, files)
      StaticFiles.new(commit, files)
    end
  end
end
