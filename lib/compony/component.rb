module Compony
  class Component
    # Include all functionality that was moved to default mixins for better overview
    Compony::ComponentMixins::Default.constants.each { |cst| include Compony::ComponentMixins::Default.const_get(cst) }

    class_attribute :setup_blocks

    attr_reader :parent_comp
    attr_reader :comp_opts
    attr_reader :action_blocks

    # root comp: component that is registered to be root of the application.
    # parent comp: component that is registered to be the parent of this comp. If there is none, this is the root comp.

    # DSL method
    def self.setup(&block)
      self.setup_blocks ||= []
      self.setup_blocks = setup_blocks.dup # This is required to prevent the parent class to see children's setup blocks.
      setup_blocks << block
    end

    # Resourceful components should return true here
    # Do not override.
    def self.resourceful?
      false
    end

    # Returns closest resourceful parent, or nil if none found
    def closest_resourceful_parent_comp
      candidate = self
      loop do
        candidate = candidate.parent_comp
        return nil if candidate.nil?
        return candidate if candidate.class.resourceful?
      end
    end

    def initialize(parent_comp = nil, index: 0, **comp_opts)
      @parent_comp = parent_comp
      @sub_comps = []
      @index = index
      @comp_opts = comp_opts
      @before_render_block = nil
      @content = nil
      @action_blocks = {}

      init_standalone
      init_labelling

      fail "#{inspect} is missing a call to `setup`." unless setup_blocks&.any?

      setup_blocks.each do |setup_block|
        instance_exec(&setup_block)
      end
      check_config!
    end

    def inspect
      "#<#{self.class.name}:#{hash}>"
    end

    # Returns the current root comp.
    # Do not overwrite.
    def root_comp
      return self unless parent_comp
      return parent_comp.root_comp
    end

    # Returns whether or not this is the root comp.
    # Do not overwrite.
    def root_comp?
      parent_comp.nil?
    end

    # Returns an identifier describing this component. Must be unique among simplings under the same parent_comp.
    # Do not override.
    def id
      "#{family_name}_#{comp_name}_#{@index}"
    end

    # Returns the id path from the root_comp.
    # Do not overwrite.
    def path
      if root_comp?
        id
      else
        "#{parent_comp.path}/#{id}"
      end
    end

    # Returns a hash for the path. Used for params prefixing.
    # Do not overwrite.
    def path_hash
      Digest::SHA256.hexdigest(path)[..4]
    end

    # Given an unprefixed name of a param, adds the path hash
    # Do not overwrite.
    def param_name(unprefixed_param_name)
      "#{path_hash}_#{unprefixed_param_name}"
    end

    # Instanciate a component with `self` as a parent
    def sub_comp(component_class, **comp_opts)
      sub = component_class.new(self, index: @sub_comps.count, **comp_opts)
      @sub_comps << sub
      return sub
    end

    # Returns the name of the module constant (=family) of this component. Do not override.
    def family_cst
      self.class.module_parent.to_s.demodulize.to_sym
    end

    # Returns the family name
    def family_name
      family_cst.to_s.underscore
    end

    # Returns the name of the class constant of this component. Do not override.
    def comp_cst
      self.class.name.demodulize.to_sym
    end

    # Returns the component name
    def comp_name
      comp_cst.to_s.underscore
    end

    def comp_class_for(...)
      Compony.comp_class_for(...)
    end

    # DSL method
    def before_render(&block)
      @before_render_block = block
    end

    # DSL method
    def content(haml = nil)
      if haml
        @content = haml
      else
        @content
      end
    end

    # Renders the component using the controller passsed to it and returns it as a string.
    # Do not overwrite.
    def render(controller, **locals)
      # Prepare request context
      # Equip helpers with the haml magic required for blocks to work, e.g. `helpers.link_to do ...`
      controller.helpers.extend Haml::Helpers
      controller.helpers.init_haml_helpers
      # Prepare a request context for render. Must transfer variables manually, as Haml::Engine does not call `evaluate`.
      request_context = RequestContext.new(self, controller)
      request_context._dslblend_transfer_inst_vars_from_main_provider
      # Call before_render hook if any
      # (not saving the request context for below's render here, as before_render_block is optional and may not be called)
      request_context.evaluate_with_backfire(&@before_render_block) if @before_render_block
      # Render, unless before_render has already issued a body (e.g. through redirecting).
      if request_context.controller.response.body.blank?
        fail "#{self.class.inspect} must define `content` or set a response body in `before_render`" if @content.blank?
        return Haml::Engine.new(@content.strip_heredoc, format: :html5).render(request_context, { **locals })
      else
        return nil # Prevent double render errors
      end
    end

    # DSL method
    def action(action_name, &block)
      @action_blocks[action_name.to_sym] = block
    end

    # Used to render all actions of this component, each button wrapped in a div with the specified class
    def render_actions(controller, wrapper_class: '', action_class: '')
      h = controller.helpers
      h.content_tag(:div, class: wrapper_class) do
        button_htmls = action_blocks.map do |_action_name, action_block|
          h.content_tag(:div, action_block.call.render(controller), class: action_class)
        end
        next h.safe_join button_htmls
      end
    end

    protected

    def check_config!; end
  end
end
