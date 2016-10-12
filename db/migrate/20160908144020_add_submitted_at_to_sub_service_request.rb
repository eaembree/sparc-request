class AddSubmittedAtToSubServiceRequest < ActiveRecord::Migration
  def change
    add_column :sub_service_requests, :submitted_at, :timestamp

    SubServiceRequest.where(status: 'submitted').each do |ssr|
      past_status = ssr.past_statuses.order('date').last
      
      ssr.update_attribute(:submitted_at, past_status.date) unless past_status.nil?
    end






    SubServiceRequest.where.not(status: 'submitted').joins(:past_statuses).where(past_statuses: { status: 'submitted' }).each do |ssr|
      last_submitted_id     = ssr.past_statuses.where(changed_to: 'submitted').order('date').last.id
      past_status_ids       = ssr.past_statuses.order('date').pluck(:id)
      last_submitted_index  = past_status_ids.index(last_submitted_id)
      previous_status_id    = past_status_ids[last_submitted_index - 1]

      ssr.update_attribute(:submitted_at, PastStatus.find(previous_status_id).date) 
    end
  end
end
