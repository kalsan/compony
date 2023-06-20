# 0.0.5

- Fix row bug for Email field type
- Auto-focus first non-hidden element in forms
- Add field type :url
- Automatically set the correct class when generating known components
- Add generator `components` that is able to mass-produce the most used components
- Make fields point to the correct `model_class` in case of STI
- Support hidden Anchormodel fields

# 0.0.4

- Unscope the namespace of resourceful components
- Add field type :email

## Steps to take

- When inheriting from components, replace `Components::Resourceful::...` by `Components::...`

# 0.0.3

- Tolerate nil anchormodels
- Fix a nil pointer bug in namespace management

# 0.0.2

- Add new model field `Attachment`
- Slightly extend documentation
- Update `Gemfile.lock`

# 0.0.1

First version