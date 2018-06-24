RSpec.shared_context :init_importing_account do |args|

  args ||= {}

  before do
    fields = {
        name: 'Telefonica-vendor',
        contractor_id: @contractor.id,
        contractor_name: @contractor.name
    }.merge(args)

    @importing_account = FactoryGirl.create(:importing_account, fields)
  end

end
