# frozen_string_literal: true

RSpec.describe Api::Rest::Admin::RoutingGroupsController, type: :controller do
  let(:user) { create :admin_user }
  let(:auth_token) { ::Knock::AuthToken.new(payload: { sub: user.id }).token }

  before do
    request.accept = 'application/vnd.api+json'
    request.headers['Content-Type'] = 'application/vnd.api+json'
    request.headers['Authorization'] = auth_token
  end

  describe 'GET index' do
    let!(:routing_groups) { RoutingGroup.all.to_a }

    before { get :index }

    it { expect(response.status).to eq(200) }
    it { expect(response_data.size).to eq(routing_groups.size) }
  end

  describe 'GET index with filters' do
    before { create_list(:routing_group, 2) }

    it_behaves_like :jsonapi_filter_by_name do
      let(:subject_record) { create(:routing_group) }
    end
  end

  describe 'GET show' do
    let!(:routing_group) { RoutingGroup.take! }

    context 'when routing_group exists' do
      before { get :show, params: { id: routing_group.to_param } }

      it { expect(response.status).to eq(200) }
      it { expect(response_data['id']).to eq(routing_group.id.to_s) }
    end

    context 'when routing_group does not exist' do
      before { get :show, params: { id: routing_group.id + 10 } }

      it { expect(response.status).to eq(404) }
      it { expect(response_data).to eq(nil) }
    end
  end

  describe 'POST create' do
    subject do
      post :create, params: {
        data: { type: 'routing-groups', attributes: attributes }
      }
    end

    context 'when attributes are valid' do
      let(:attributes) { { name: 'test-name' } }

      it 'creates routing group' do
        expect { subject }.to change { RoutingGroup.count }.by(1)
        expect(response.status).to eq(201)
        record = RoutingGroup.last!
        expect(record).to have_attributes(attributes)
      end
    end

    context 'when attributes are invalid' do
      let(:attributes) { { name: nil } }

      it 'does not create routing group' do
        expect { subject }.to change { RoutingGroup.count }.by(0)
        expect(response.status).to eq(422)
      end
    end
  end

  describe 'PUT update' do
    let!(:routing_group) { create :routing_group }
    before do
      put :update, params: {
        id: routing_group.to_param, data: { type: 'routing-groups',
                                            id: routing_group.to_param,
                                            attributes: attributes }
      }
    end

    context 'when attributes are valid' do
      let(:attributes) { { name: 'name' } }

      it { expect(response.status).to eq(200) }
      it { expect(routing_group.reload.name).to eq('name') }
    end

    context 'when attributes are invalid' do
      let(:attributes) { { name: nil } }

      it { expect(response.status).to eq(422) }
      it { expect(routing_group.reload.name).to_not eq(nil) }
    end
  end

  describe 'DELETE destroy' do
    subject { delete :destroy, params: { id: routing_group.to_param } }

    let!(:routing_group) { create :routing_group }

    it 'deletes routing group' do
      expect { subject }.to change { RoutingGroup.count }.by(-1)
      expect(response.status).to eq(204)
    end
  end
end
