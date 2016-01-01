require 'code_tour'

t = CodeTour.define do
  version_control_integration CodeTour::Git
  renderer CodeTour::MarkdownRenderer

  block(show('d9bff6dfb')) do
    "####Have a diff

     And some commentary to go with it.

     That's the point really"
  end

  block(static('HEAD', ['lib/code_tour/version.rb'])) do
    "And a version file"
  end
end

puts t.render_blocks
