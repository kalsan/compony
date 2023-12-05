module Compony
  module Version
    MAJOR = 0
    MINOR = 2
    PATCH = 0

    EDGE = false

    LABEL = [MAJOR, MINOR, PATCH, EDGE ? 'edge' : nil].compact.join('.')
  end
end
