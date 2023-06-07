class ComponentsGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  def add_component
    @family = name.underscore.pluralize # Force plural
    @family_cst = @family.camelize.pluralize # Force plural

    %w[Destroy Edit Form New].each do |comp_cst|
      generate "component #{name}::#{comp_cst}"
    end
  end
end
