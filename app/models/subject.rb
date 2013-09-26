class Subject < ActiveRecord::Base
  audited

  belongs_to :arm
  has_one :calendar, :dependent => :destroy

  attr_accessible :name
  attr_accessible :mrn
  attr_accessible :dob
  attr_accessible :gender
  attr_accessible :ethnicity
  attr_accessible :external_subject_id
  attr_accessible :calendar_attributes
  attr_accessible :status

  accepts_nested_attributes_for :calendar

  after_create { self.create_calendar }

  def procedures
    appointments = Appointment.where("calendar_id = ?", self.calendar.id).includes(:procedures)
    procedures = appointments.collect{|x| x.procedures}.flatten
  end
end
