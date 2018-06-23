RSpec.describe Api::Rest::Admin::Routing::AreaPrefixesController, type: :controller do

  include_context :jsonapi_admin_headers

  let(:resource_type) { 'area-prefixes' }

  let(:record) { create :area_prefix }

  describe 'GET index' do
    let!(:records) { create_list :area_prefix, 2 }
    before { get :index }

    it { expect(response.status).to eq(200) }
    it { expect(response_data.size).to eq(Routing::AreaPrefix.count) }
  end

  describe 'GET show' do
    before { get :show, id: record.id }

    it 'receive expected fields' do
      expect(response_data.deep_symbolize_keys).to a_hash_including(
        id: record.id.to_s,
        attributes: {
          prefix: record.prefix
        }
      )
    end
  end

  describe 'POST create' do
    before do
      post :create, data: { type: resource_type,
                            attributes: attributes,
                            relationships: relationships }
    end

    let(:attributes) do
      { prefix: '777' }
    end

    let(:relationships) do
      {
        'area': wrap_relationship(:'areas', create(:area).to_param)
      }
    end

    it 'creates proper record' do
      expect(response.status).to eq(201)
      expect(Routing::AreaPrefix.last).to have_attributes(
        prefix: attributes[:prefix],
        area_id: Routing::Area.last.id
      )
    end
  end

  describe 'PUT update' do
    before do
      put :update, id: record.to_param, data: { type: resource_type,
                                                id: record.to_param,
                                                attributes: attributes }
    end

    let(:attributes) do
      { prefix: '888' }
    end

    it { expect(response.status).to eq(200) }
    it { expect(record.reload.prefix).to eq(attributes[:prefix]) }
  end

  describe 'DELETE destroy' do
    before { delete :destroy, id: record.to_param }

    it { expect(response.status).to eq(204) }
    it { expect(Routing::AreaPrefix.count).to eq(0) }
  end

end
