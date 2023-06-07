module Compony
  module ModelFields
    class Url < Base
      def value_for(data, controller: nil, **_)
        return transform_and_join(data.send(@name), controller:) do |el|
          fail('Must pass controller to generate the link to the link.') unless controller
          return controller.helpers.link_to(el, el, target: '_blank', rel: 'noopener')
        end
      end
    end
  end
end
