module Compony
  module ModelFields
    class Email < Base
      def value_for(data, controller: nil, **_)
        return transform_and_join(data.send(@name), controller:) do |el|
          fail('Must pass controller to generate the link to the email.') unless controller
          return nil unless el
          return controller.helpers.mail_to(el)
        end
      end
    end
  end
end
