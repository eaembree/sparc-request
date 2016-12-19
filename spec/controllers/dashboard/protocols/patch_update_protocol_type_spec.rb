# Copyright © 2011-2016 MUSC Foundation for Research Development~
# All rights reserved.~

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:~

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.~

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following~
# disclaimer in the documentation and/or other materials provided with the distribution.~

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products~
# derived from this software without specific prior written permission.~

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,~
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT~
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL~
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS~
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR~
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.~

require 'rails_helper'

RSpec.describe Dashboard::ProtocolsController do
  describe 'patch update_protocol_type' do
    context 'user is an Authorized User' do
      context 'user not authorized to edit Protocol' do
        before(:each) do
          @logged_in_user = build_stubbed(:identity)
          @protocol = findable_stub(Protocol) do
            build_stubbed(:protocol)
          end
          authorize(@logged_in_user, @protocol, can_edit: false)
          log_in_dashboard_identity(obj: @logged_in_user)
          xhr :patch, :update_protocol_type, id: @protocol.id
        end

        it "should use ProtocolAuthorizer to authorize user" do
          expect(ProtocolAuthorizer).to have_received(:new).
            with(@protocol, @logged_in_user)
        end

        it { is_expected.to render_template "dashboard/shared/_authorization_error" }
        it { is_expected.to respond_with :ok }
      end

      context "user authorized to edit Protocol" do
        before(:each) do
          @logged_in_user = build_stubbed(:identity)
          log_in_dashboard_identity(obj: @logged_in_user)

          @protocol = findable_stub(Protocol) do
            build_stubbed(:protocol, type: "Study")
          end
          allow(@protocol).to receive(:update_attribute)
          allow(@protocol).to receive(:populate_for_edit)
          authorize(@logged_in_user, @protocol, can_edit: true)

          xhr :patch, :update_protocol_type, id: @protocol.id, type: "Project"
        end

        it 'should update Protocol type to params[:type]' do
          expect(@protocol).to have_received(:update_attribute).with(:type, "Project")
        end

        it 'should populate Protocol for edit' do
          expect(@protocol).to have_received(:populate_for_edit)
        end

        it { is_expected.to render_template "dashboard/protocols/update_protocol_type" }
        it { is_expected.to respond_with :ok }
      end
    end

    context 'user has Admin access' do
      context 'user not authorized to view Protocol' do
        before :each do
          @logged_in_user = create(:identity)
          @protocol       = create(:protocol_without_validations, type: 'Project')

          log_in_dashboard_identity(obj: @logged_in_user)

          xhr :patch, :update_protocol_type, id: @protocol.id
        end

        it 'should set @admin to false' do
          expect(assigns(:admin)).to eq(false)
        end

        it { is_expected.to respond_with :ok }
        it { is_expected.to render_template "dashboard/shared/_authorization_error" }
      end

      context 'user authorized to view Protocol as Super User' do
        before :each do
          @logged_in_user = create(:identity)
          @protocol       = create(:protocol_without_validations, type: 'Project')
          organization    = create(:organization)
          service_request = create(:service_request_without_validations, protocol: @protocol)
                            create(:sub_service_request_without_validations, organization: organization, service_request: service_request, status: 'draft')
                            create(:super_user, identity: @logged_in_user, organization: organization)

          log_in_dashboard_identity(obj: @logged_in_user)

          xhr :patch, :update_protocol_type, id: @protocol.id
        end

        it 'should set @admin to true' do
          expect(assigns(:admin)).to eq(true)
        end

        it { is_expected.to respond_with :ok }
      end

      context 'user authorized to view Protocol as Service Provider' do
        before :each do
          @logged_in_user = create(:identity)
          @protocol       = create(:protocol_without_validations, type: 'Project')
          organization    = create(:organization)
          service_request = create(:service_request_without_validations, protocol: @protocol)
                            create(:sub_service_request_without_validations, organization: organization, service_request: service_request, status: 'draft')
                            create(:service_provider, identity: @logged_in_user, organization: organization)

          log_in_dashboard_identity(obj: @logged_in_user)

          xhr :patch, :update_protocol_type, id: @protocol.id
        end

        it 'should set @admin to true' do
          expect(assigns(:admin)).to eq(true)
        end

        it { is_expected.to respond_with :ok }
      end
    end
  end
end
