# Copyright © 2011 MUSC Foundation for Research Development
# All rights reserved.

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
# disclaimer in the documentation and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

class Dashboard::ProtocolsController < Dashboard::BaseController

  respond_to :html, :json, :xlsx

  before_filter :find_protocol, only: [:show, :view_full_calendar, :update_from_fulfillment, :edit, :update, :update_protocol_type, :display_requests]
  before_filter :protocol_authorizer_view, only: [:show, :view_full_calendar]
  before_filter :protocol_authorizer_edit, only: [:update_from_fulfillment, :edit, :update, :update_protocol_type]

  def index
    respond_to do |format|
      format.html {
        session[:breadcrumbs].clear
        render
      }
      format.json {
        protocol_finder = Dashboard::ProtocolFinder.new(current_user, params)
        @protocols = protocol_finder.protocols
        @total_protocols = protocol_finder.total_protocols
        render
      }
    end
  end

  def show
    @protocol_role = @protocol.project_roles.find_by_identity_id(@user.id)

    respond_to do |format|
      format.js   { render }
      format.html {
        session[:breadcrumbs].clear.add_crumbs(protocol_id: @protocol.id)
        @permission_to_edit = @protocol_role.can_edit?
        @protocol_type = @protocol.type.capitalize
        @service_requests = @protocol.service_requests
        render
      }
      format.xlsx { render }
    end
  end

  def new
    @protocol = Study.new
    @protocol.project_roles.new(role: "primary-pi", project_rights: "approve")
    @protocol.requester_id = current_user.id
    @protocol.populate_for_edit
    @errors = nil
    @portal = true
    @current_step = 'protocol'
    session[:protocol_type] = 'study'
  end

  def create
    @current_step = params[:current_step]
    @protocol = Study.new(params[:study])
    @protocol.validate_nct = true
    @portal = params[:portal]
    session[:protocol_type] = 'study'
    @portal = params[:portal]

    # @protocol.assign_attributes(params[:study] || params[:project])
    if @current_step == 'go_back'
      @current_step = 'protocol'
      @protocol.populate_for_edit
    elsif @current_step == 'protocol' and @protocol.group_valid? :protocol
      @current_step = 'user_details'
      @protocol.populate_for_edit
    elsif @current_step == 'user_details' and @protocol.valid?
      @protocol.save
      @current_step = 'return_to_portal'
      if USE_EPIC
        if @protocol.selected_for_epic
          @protocol.ensure_epic_user
          Notifier.notify_for_epic_user_approval(@protocol).deliver unless QUEUE_EPIC
        end
      end
    elsif @current_step == 'cancel_protocol'
      @current_step = 'return_to_portal'
    else
      # TODO: Is this neccessary?
      @errors = @current_step == 'protocol' ? @protocol.grouped_errors[:protocol].try(:messages) : @protocol.grouped_errors[:user_details].try(:messages)
      @protocol.populate_for_edit
    end
  end

  def edit
    @protocol.populate_for_edit if @protocol.type == "Study"
    @protocol.valid?
    session[:breadcrumbs].
      clear.
      add_crumbs(protocol_id: @protocol.id, edit_protocol: true)

    respond_to do |format|
      format.html
    end
  end

  def update
    attrs = params[@protocol.type.downcase.to_sym]
    if @protocol.update_attributes attrs
      flash[:success] = "Study Updated!"
      redirect_to dashboard_protocol_path(@protocol)
    else
      @protocol.populate_for_edit if @protocol.type == "Study"
      redirect_to edit_dashboard_protocol_path(@protocol)
    end
  end

  def update_protocol_type
    # Using update_attribute here is intentional, type is a protected attribute
    if @protocol.update_attribute(:type, params[:type])
      @protocol = Protocol.find @protocol.id #Protocol type has been converted, this is a reload
      @protocol.populate_for_edit if @protocol.type == "Study"
      @protocol.valid?
      @form_partial = "dashboard/protocols/form/#{params[:type].downcase}_form"
      flash[:success] = "Protocol Type Updated!"
    else
      @errors = @protocol.errors
    end
  end

  def update_from_fulfillment
    if @protocol.update_attributes(params[:protocol])
      render :nothing => true
    else
      respond_to do |format|
        format.js { render :status => 500, :json => clean_errors(@protocol.errors) }
      end
    end
  end

  # @TODO: add to an authorization filter?
  def add_associated_user
    @protocol = Protocol.find(params[:id])

    @project_role = @protocol.project_roles.build(:identity_id => @user.id)
    respond_to do |format|
      format.js
      format.html
    end
  end

  def view_full_calendar
    @service_request = @protocol.any_service_requests_to_display?

    arm_id = params[:arm_id] if params[:arm_id]
    page = params[:page] if params[:page]
    session[:service_calendar_pages] = params[:pages] if params[:pages]
    session[:service_calendar_pages][arm_id] = page if page && arm_id
    @tab = 'calendar'
    @portal = params[:portal]
    if @service_request
      @pages = {}
      @protocol.arms.each do |arm|
        new_page = (session[:service_calendar_pages].nil?) ? 1 : session[:service_calendar_pages][arm.id.to_s].to_i
        @pages[arm.id] = @service_request.set_visit_page new_page, arm
      end
    end
    @merged = true
    respond_to do |format|
      format.js
      format.html
    end
  end

  private

  def find_protocol
    @protocol = Protocol.find(params[:id])
  end

  # TODO: Move this somewhere else. Short on time, though. - nb
  def merge_attributes(protocol, data)
    protocol.instance_values.each do |k, v|
      data.merge!({k => v}) unless data.include?(k)
    end
  end

  def fix_funding(data)
    if data["funding_status"] == "pending_funding" && data["_type"] != "project"
      data.delete("funding_source")
      data.delete("funding_source_other")
      data.delete("funding_start_date")
    elsif data["funding_status"] == "funded"
      data.delete("potential_funding_source")
      data.delete("potential_funding_source_other")
      data.delete("potential_funding_start_date")
    end
  end
end
