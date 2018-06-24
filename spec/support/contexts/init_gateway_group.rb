RSpec.shared_context :init_gateway_group do |args|

  args ||= {}

  before do
    fields = {
        name: 'iBasis',
        vendor_id: @contractor.id
    }.merge(args)

    @gateway_group = FactoryGirl.create(:gateway_group, fields)
  end

end
