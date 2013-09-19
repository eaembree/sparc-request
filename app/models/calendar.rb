class Calendar < ActiveRecord::Base
  audited

  belongs_to :subject
  has_many :appointments, :dependent => :destroy

  attr_accessible :appointments_attributes

  accepts_nested_attributes_for :appointments

  def populate(visit_groups)
    visit_groups.each do |visit_group|
      appt = self.appointments.create(visit_group_id: visit_group.id)
      appt.populate_procedures(visit_group.visits)
    end
  end

  def completed_total
    completed_procedures = self.appointments.select{|x| x.completed?}.collect{|y| y.procedures}.flatten
    return completed_procedures.sum{|x| x.total}
  end
  
end
