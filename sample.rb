require 'code_tour'

t = CodeTour.define do
  version_control_integration CodeTour::Git
  renderer CodeTour::TextRenderer
  block(show('d9bff6dfb')) { "Have a diff" }
  block(static('HEAD', ['lib/code_tour/version.rb'])) do
    "And a version file"
  end
end

puts t.render_blocks
