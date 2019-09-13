# Copyright © 2011-2019 MUSC Foundation for Research Development
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

class VisitGroup < ApplicationRecord
  self.per_page = Visit.per_page

  include RemotelyNotifiable
  include Comparable

  audited

  belongs_to :arm
  has_many :visits, :dependent => :destroy
  
  has_many :line_items_visits, through: :visits
  
  ########################
  ### CWF Associations ###
  ########################

  has_many :fulfillment_visit_groups, class_name: 'Shard::Fulfillment::VisitGroup', foreign_key: :sparc_id

  acts_as_list scope: :arm

  after_create :build_visits, if: Proc.new { |vg| vg.arm.present? }
  after_create :increment_visit_count, if: Proc.new { |vg| vg.arm.present? && vg.arm.visit_count < vg.arm.visit_groups.count }
  
  before_update :move_previous_visit_days, if: Proc.new{ |vg| vg.moved_and_days_need_update? }

  before_destroy :decrement_visit_count, if: Proc.new { |vg| vg.arm.present? && vg.arm.visit_count >= vg.arm.visit_groups.count  }

  validates :name, :position, :day, :window_before, :window_after, presence: true

  validates :position, presence: true
  validates :window_before, :window_after, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, if: Proc.new{ |vg| vg.day.present? }

  validates :day, numericality: { only_integer: true }, if: Proc.new{ |vg| vg.day.present? }

  validate :day_must_be_in_order, if: Proc.new{ |vg| vg.day.present? }

  default_scope { order(:position) }

  def lower_position
    self.position - 1
  end

  def <=> (other_vg)
    return unless other_vg.respond_to?(:day)
    self.day <=> other_vg.day
  end

  def self.admin_day_multiplier
    5
  end

  def identifier
    "#{self.name}" + (self.day.present? ? " (#{self.class.human_attribute_name(:day)} #{self.day})" : "")
  end

  def insertion_name
    I18n.t('visit_groups.before') + " " + self.identifier
  end

  ### audit reporting methods ###

  def audit_label audit
    "#{arm.name} #{name}"
  end

  def audit_field_value_mapping
    {"arm_id" => "Arm.find(ORIGINAL_VALUE).name"}
  end

  ### end audit reporting methods ###

  def any_visit_quantities_customized?(service_request)
    visits.any? { |visit| ((visit.quantities_customized?) && (visit.line_items_visit.line_item.service_request_id == service_request.id)) }
  end

  def moved_and_days_need_update?
    self.persisted? && position_changed? && day_changed? && self.day == self.higher_item.day
  end

  def in_order?
    self.arm.visit_groups.where.not(id: self.id, day: nil).where(
      VisitGroup.arel_table[:position].lt(self.position).and(
      VisitGroup.arel_table[:day].gteq(self.day)).or(
      VisitGroup.arel_table[:position].gt(self.position).and(
      VisitGroup.arel_table[:day].lteq(self.day)))
    ).none?
  end

  def per_patient_subtotals
    self.visits.sum{ |v| v.cost || 0.00 }
  end
    
  private

  def build_visits
    self.arm.line_items_visits.each do |liv|
      self.visits.create(line_items_visit: liv)
    end
  end

  def increment_visit_count
    self.arm.increment!(:visit_count)
  end

  def decrement_visit_count
    self.arm.decrement!(:visit_count)
  end

  def move_previous_visit_days
    self.higher_items.select{ |vg| vg.higher_item.nil? || (vg.day.present? && vg.day == vg.higher_item.day + 1) }.sort_by(&:position).each do |v|
      v.update_attribute(:day, v.day - 1)
    end
  end

  def day_must_be_in_order
    errors.add(:day, :out_of_order) unless moved_and_days_need_update? || in_order?
  end
end
