class Payment < ActiveRecord::Base
  audited

  attr_accessible :sub_service_request_id
  attr_accessible :date_submitted
  attr_accessible :formatted_date_submitted
  attr_accessible :amount_invoiced
  attr_accessible :amount_received
  attr_accessible :date_received
  attr_accessible :formatted_date_received
  attr_accessible :payment_method
  attr_accessible :details
  attr_accessible :uploads_attributes
  attr_accessible :percent_subsidy
  
  validates :date_submitted, presence: true
  validates :amount_invoiced, numericality: true
  validates :amount_received, numericality: true, allow_nil: true

  has_many :uploads, class_name: 'PaymentUpload', dependent: :destroy
  belongs_to :sub_service_request

  accepts_nested_attributes_for :uploads, allow_destroy: true


  PAYMENT_METHOD_OPTIONS = ['Check', 'Cash', 'EFT', 'IIT', 'SCTR Award'].freeze

  def formatted_date_received
    format_date self.date_received
  end

  def formatted_date_received=(d)
    self.date_received = parse_date(d)
  end

  def formatted_date_submitted
    format_date self.date_submitted
  end

  def formatted_date_submitted=(d)
    self.date_submitted= parse_date(d)
  end
  
  ### audit reporting methods ###
  
  def audit_excluded_fields
    {'create' => ['sub_service_request_id']}
  end
  
  def audit_label audit
    if audit.action == 'create'
      return "New Payment"
    else
      return "Editing Payment"
    end
  end

  ### end audit reporting methods ###

  private

  def format_date(d)
    d.try(:strftime, '%-m/%d/%Y')
  end

  def parse_date(str)
    begin
      Date.strptime(str.to_s.strip, '%m/%d/%Y')  
    rescue ArgumentError => e
      nil
    end
  end
end
