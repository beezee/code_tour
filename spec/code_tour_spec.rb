require 'spec_helper'

module TestRender

  def render(blocks)
    blocks.map do |b|
      "{{\n"+
      b.sample.map do |f|
        f.lines.map { |s| "#{s.old_number} - #{s.content}" }.join("\n")
      end.join("\n") +
      "\n}}\n" +
      "#{b.content}"
    end.join("\n")
  end
end

module TestCF

  def format_content(content)
    content.upcase
  end
end

module TestVCI

  def validate_code_sample!(sample)
    nil
  end

  def format_sample(sample)
    [CodeTour::CodeSample::SampleFile.new("file",
      sample.downcase.split("\n").each_with_index.map do |l, i|
        CodeTour::CodeSample::SampleLine.new(i+1, nil, l)
      end)]
  end
end

describe CodeTour do
  it 'has a version number' do
    expect(CodeTour::VERSION).not_to be nil
  end

  it 'formats blocks using provided implementations' do
    t = CodeTour.define do
      version_control_integration(TestVCI)
      content_formatter(TestCF)
      block("FOO") { "bar" }
    end
    expect(t.formatted_blocks).to eq(
      [CodeTour::Definition::Block.new(
        [CodeTour::CodeSample::SampleFile.new("file",
          [CodeTour::CodeSample::SampleLine.new(1, nil, "foo")])], "BAR")])
  end

  it 'renders blocks using provided implementations' do
    t = CodeTour.define do
      version_control_integration(TestVCI)
      content_formatter(TestCF)
      renderer(TestRender)
      block("FOO") { "bar" }
      block("BAZ\nBAR") { "quux" }
    end
    expected =
      "{{
       1 - foo
       }}
       BAR
       {{
       1 - baz
       2 - bar
       }}
       QUUX".squeeze(" ").split("\n")
            .map(&:lstrip).join("\n")
    expect(t.render_blocks).to eq(expected)
  end
end
