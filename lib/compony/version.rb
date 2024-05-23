module Compony
  module Version
    LABEL = (Pathname.new(__FILE__).dirname.dirname.dirname / 'VERSION').read
  end
end
