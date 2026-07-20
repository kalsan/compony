SimpleForm.setup do |config|
  config.wrappers :default, class: :input do |b|
    b.use :html5
    b.use :label_input
    b.use :error, wrap_with: { tag: :span, class: :error }
  end
  config.default_wrapper = :default
  config.button_class = 'btn'
end
