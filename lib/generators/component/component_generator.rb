class ComponentGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  def add_component
    segments = name.underscore.split('/')
    fail('NAME must be of the form Family::ComponentName or family/component_name') if segments.size != 2
    @family, @comp = segments
    @family = @family.pluralize # Force plural
    @family_cst = @family.camelize.pluralize # Force plural
    @comp_cst = @comp.camelize # Tolerate singular and plural

    case @comp_cst
    when 'Destroy'
      template 'destroy.rb.erb', "app/components/#{@family}/#{@comp}.rb"
    when 'Edit'
      template 'edit.rb.erb', "app/components/#{@family}/#{@comp}.rb"
    when 'Form'
      template 'form.rb.erb', "app/components/#{@family}/#{@comp}.rb"
    when 'New'
      template 'new.rb.erb', "app/components/#{@family}/#{@comp}.rb"
    else
      template 'component.rb.erb', "app/components/#{@family}/#{@comp}.rb"
    end
  end
end
