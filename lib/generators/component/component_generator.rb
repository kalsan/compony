class ComponentGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  def add_component
    segments = name.underscore.split('/')
    fail('NAME must be of the form Family::ComponentName or family/component_name') if segments.size != 2
    @family, @comp = segments
    @family = @family.pluralize # Force plural
    @family_cst = @family.camelize.pluralize # Force plural
    @comp_cst = @comp.camelize # Tolerate singular and plural

    template 'component.rb.erb', "app/components/#{@family}/#{@comp}.rb"
  end
end
