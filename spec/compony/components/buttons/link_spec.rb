RSpec.describe Compony::Components::Buttons::Link do
  let(:controller) do
    ApplicationController.new.tap do |c|
      c.request = ActionDispatch::TestRequest.create
      c.response = ActionDispatch::TestResponse.new
    end
  end

  # Outside a request, the controller reports a body, which would make the component skip rendering.
  before { allow(controller).to receive(:response_body).and_return(nil) }

  def render_button(klass = described_class, **)
    klass.new(**).render(controller)
  end

  it 'renders a link to the given href' do
    expect(render_button(label: 'Go', href: '/users')).to eq('<a href="/users">Go</a>')
  end

  it 'renders an <a> without href (and without a javascript: URL) when no href is given' do
    expect(render_button(label: 'Nothing')).to eq('<a>Nothing</a>')
  end

  it 'renders a submit button when given type: :submit' do
    expect(render_button(label: 'Save', type: :submit, class: 'primary')).to eq('<button class="primary" type="submit">Save</button>')
  end

  it 'renders a disabled submit button when given the class disabled' do
    expect(render_button(label: 'Save', type: :submit, class: 'disabled')).to include('disabled="disabled"')
  end

  it 'never renders inline JavaScript' do
    [{ label: 'a' }, { label: 'b', href: '/x' }, { label: 'c', type: :submit }, { label: 'd', class: 'disabled' }].each do |opts|
      expect(render_button(**opts)).not_to match(/javascript:|\bon[a-z]+=/)
    end
  end

  describe 'button styles overriding content' do
    let(:rendering_through_helper) do
      Class.new(described_class) do
        def self.name = 'HelperButton'
        setup do
          content do
            concat component.link_or_button(capture { span @label }, **@comp_opts, class: 'fancy')
          end
        end
      end
    end

    let(:calling_link_to) do
      Class.new(described_class) do
        def self.name = 'LegacyButton'
        setup do
          content do
            concat link_to(@label, @href, **@comp_opts)
          end
        end
      end
    end

    it 'can render a submit button through link_or_button' do
      expect(render_button(rendering_through_helper, label: 'Save', type: :submit)).to eq('<button class="fancy" type="submit"><span>Save</span></button>')
    end

    it 'keeps the former markup when calling link_to without a href' do
      expect(render_button(calling_link_to, label: 'Nothing')).to eq('<a href="javascript:void(0)">Nothing</a>')
    end

    it 'fails loudly when given a type but rendering a link' do
      expect { render_button(calling_link_to, label: 'Save', type: :submit) }.to raise_error(/did not render through `link_or_button`/)
    end
  end
end
