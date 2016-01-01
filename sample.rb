require 'code_tour'

t = CodeTour.define do
  version_control_integration CodeTour::Git
  renderer CodeTour::TextRenderer
  block(diff('HEAD')) { "Have a diff" }
end

puts t.render_blocks
