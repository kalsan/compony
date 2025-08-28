class ComponentGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  def add_component
    segments = name.underscore.split('/')
    fail("NAME must be of the form Family::ComponentName or family/component_name but got #{name.inspect}") if segments.size != 2
    @family, @comp = segments
    @family = @family.pluralize # Force plural
    @family_cst = @family.camelize.pluralize # Force plural
    @comp_cst = @comp.camelize # Tolerate singular and plural
    @args = args

    # If BaseComponents::ComponentAboutToBeGenerated is present, inherit from that
    if defined?(BaseComponents.const_defined?(@comp_cst))
      @parent_base_component_class = BaseComponents.const_get(@comp_cst)
      template 'with_base_component.rb.erb', "app/components/#{@family}/#{@comp}.rb"
      return
    end
    # If a Compony component with the specified name exists, inherit from that
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
      # Inherit from regular component
      template 'component.rb.erb', "app/components/#{@family}/#{@comp}.rb"
    end
  end
end
