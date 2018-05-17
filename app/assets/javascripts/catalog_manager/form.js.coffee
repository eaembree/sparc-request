# Copyright © 2011-2017 MUSC Foundation for Research Development
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

##############################################
###          Org General Info              ###
##############################################
$ ->
  $(document).on 'click', '#enable-all-services label', ->
    $(this).addClass('active')
    $(this).children('input').prop('checked')
    $(this).siblings('.active').removeClass('active')

  $(document).on 'click', '#display-in-sparc .toggle', ->
    if $(this).find("[id*='_is_available']").prop('checked')
      $('#enable-all-services').removeClass('hidden')
    else
      $('#enable-all-services').addClass('hidden')

  ##############################################
  ###          Org User Rights               ###
  ##############################################

  $(document).on 'change', '.super-user-checkbox', ->
    $.ajax
      type: if $(this).prop('checked') then 'POST' else 'DELETE'
      url: '/catalog_manager/super_user'
      data:
        super_user:
          identity_id: $(this).data('identity-id')
          organization_id: $(this).data('organization-id')

  $(document).on 'change', '.catalog-manager-checkbox', ->
    identity_id = $(this).data('identity-id')
    checked = $(this).prop('checked')
    $.ajax
      type: if checked then 'POST' else 'DELETE'
      url: '/catalog_manager/catalog_manager'
      data:
        catalog_manager:
          identity_id: identity_id
          organization_id: $(this).data('organization-id')
      success: ->
        $("#cm-edit-historic-data-#{identity_id}").prop('disabled', !checked)
        if !checked
          $("#cm-edit-historic-data-#{identity_id}").prop('checked', false)

  $(document).on 'change', '.service-provider-checkbox', ->
    identity_id = $(this).data('identity-id')
    checked = $(this).prop('checked')
    $.ajax
      type: if checked then 'POST' else 'DELETE'
      url: '/catalog_manager/service_provider'
      data:
        service_provider:
          identity_id: identity_id
          organization_id: $(this).data('organization-id')
      success: ->
        $("#sp-is-primary-contact-#{identity_id}").prop('disabled', !checked)
        $("#sp-hold-emails-#{identity_id}").prop('disabled', !checked)
        if !checked
          $("#sp-is-primary-contact-#{identity_id}").prop('checked', false)
          $("#sp-hold-emails-#{identity_id}").prop('checked', false)

  $(document).on 'change', '.clinical-provider-checkbox', ->
    $.ajax
      type: if $(this).prop('checked') then 'POST' else 'DELETE'
      url: '/catalog_manager/clinical_provider'
      data:
        clinical_provider:
          identity_id: $(this).data('identity-id')
          organization_id: $(this).data('organization-id')

  $(document).on 'change', '.cm-edit-historic-data', ->
    $.ajax
      type: 'PUT'
      url: 'catalog_manager/catalog_manager/'
      data:
        catalog_manager:
          identity_id: $(this).data('identity-id')
          organization_id: $(this).data('organization-id')
          edit_historic_data: $(this).prop('checked')

  $(document).on 'change', '.sp-is-primary-contact', ->
    $.ajax
      type: 'PUT'
      url: 'catalog_manager/service_provider/'
      data:
        service_provider:
          identity_id: $(this).data('identity-id')
          organization_id: $(this).data('organization-id')
          is_primary_contact: $(this).prop('checked')

  $(document).on 'change', '.sp-hold-emails', ->
    $.ajax
      type: 'PUT'
      url: 'catalog_manager/service_provider/'
      data:
        service_provider:
          identity_id: $(this).data('identity-id')
          organization_id: $(this).data('organization-id')
          hold_emails: $(this).prop('checked')

  $(document).on 'click', '.remove-user-rights', (event) ->
    event.preventDefault()
    if confirm (I18n['catalog_manager']['organization_form']['user_rights']['remove_confirm'])
      identity_id = $(this).data('identity-id')
      $.ajax
        type: 'DELETE'
        url: 'catalog_manager/user_right'
        data:
          user_rights:
            identity_id: identity_id
            organization_id: $(this).data('organization-id')

  $(document).on 'click', '.cancel-user-rights', (event) ->
    event.preventDefault()
    $(this).closest('.row').fadeOut(1000, () -> $(this).remove())

  ##############################################
  ###         Org Associated Surveys         ###
  ##############################################

  $(document).on 'click', 'button.remove-associated-survey', (event) ->
    associated_survey_link = $(this).closest('.form-group.row').find('.associated_survey_link')[0]
    associated_survey_id = $(associated_survey_link).data('id')
    surveyable_id = $(this).data('id')
    if confirm(I18n['catalog_manager']['organization_form']['surveys']['survey_delete'])
      $.ajax
        type: 'POST'
        url: "catalog_manager/catalog/remove_associated_survey"
        data:
          associated_survey_id: associated_survey_id
          surveyable_id: surveyable_id


  $(document).on 'click', 'button.add-associated-survey', (event) ->
    if $('#new_associated_survey').val() == ''
      alert "No survey selected"
    else
      survey_id = $(this).closest('.form-group.row').find('.new_associated_survey')[0].value
      surveyable_type = $(this).data('type')
      surveyable_id = $(this).data('id')
      $.ajax
        type: 'POST'
        url: "catalog_manager/catalog/add_associated_survey"
        data:
          survey_id: survey_id
          surveyable_type : surveyable_type
          surveyable_id : surveyable_id

  ##############################################
  ###          Org Fulfillment               ###
  ##############################################

  $(document).on 'change', '.clinical-provider-checkbox', ->
    $.ajax
      type: if $(this).prop('checked') then 'POST' else 'DELETE'
      url: '/catalog_manager/super_user'
      data:
        super_user:
          identity_id: $(this).data('identity-id')
          organization_id: $(this).data('organization-id')

  $(document).on 'click', '.remove-fulfillment-rights', (event) ->
    event.preventDefault()
    if confirm (I18n['catalog_manager']['organization_form']['user_rights']['remove_confirm'])
      identity_id = $(this).data('identity-id')
      $.ajax
        type: 'POST'
        url: 'catalog_manager/organizations/remove_fulfillment_rights_row'
        data:
          fulfillment_rights:
            identity_id: identity_id
            organization_id: $(this).data('organization-id')

  $(document).on 'click', '.cancel-fulfillment-rights', (event) ->
    event.preventDefault()
    $(this).closest('.row').fadeOut(1000, () -> $(this).remove())


  ##############################################
  ###          Service Components            ###
  ##############################################

  $(document).on 'click', 'button.remove-service-component', (event) ->
    component = $(this).closest('.form-group.row').find('input.component_string')[0].value
    service_id = $(this).data('service')
    if confirm (I18n['catalog_manager']['service_form']['remove_component_confirm'])
      $.ajax
        type: 'POST'
        url: "catalog_manager/services/change_components"
        data:
          component: component
          service_id: service_id

  $(document).on 'click', 'button.add-service-component', (event) ->
    component = $(this).closest('.form-group.row').find('input.component_string')[0].value
    service_id = $(this).data('service')
    $.ajax
      type: 'POST'
      url: "catalog_manager/services/change_components"
      data:
        component: component
        service_id: service_id

  ##############################################
  ###          Related Services              ###
  ##############################################

  $(document).on 'click', 'button.remove-related-services', (event) ->
    service_relation_id = $(this).data('service-relation-id')
    if confirm (I18n['catalog_manager']['related_services_form']['remove_related_service_confirm'])
      $.ajax
        type: 'POST'
        url: "catalog_manager/services/disassociate"
        data: 
          service_relation_id: service_relation_id

  $(document).on 'click', 'button.add-related-services', (event) ->
    service_id = $(this).data('service')
    $.ajax
      type: 'POST'
      url: "catalog_manager/services/associate"
      data: 
        service_id: service_id

  $(document).on 'click', '.linked_quantity', (event) ->
    service_relation_id = $(this).data('service_relation_id')
    linked_quantity = $(this).val()
    $.ajax
      type: 'POST'
      url: "catalog_manager/services/set_linked_quantity"
      data: 
        service_relation_id: service_relation_id
        linked_quantity: linked_quantity

  $(document).on 'change', '.linked_quantity_total', (event) ->
    service_relation_id = $(this).data('service_relation_id')
    linked_quantity_total = $(this).val()
    $.ajax
      type: 'POST'
      url: "catalog_manager/services/set_linked_quantity_total"
      data: 
        service_relation_id: service_relation_id
        linked_quantity_total: linked_quantity_total

  $(document).on 'change', '.optional', (event) ->
    console.log 'optional'
    service_relation_id = $(this).data('service-relation-id')
    optional = $(this).val()
    $.ajax
      type: 'POST'
      url: "catalog_manager/services/set_optional"
      data: 
        service_relation_id: service_relation_id
        optional: optional

  ##############################################
  ###          Clinical Providers            ###
  ##############################################