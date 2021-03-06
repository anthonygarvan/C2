class Approval < ActiveRecord::Base
  include WorkflowModel
  has_paper_trail

  workflow do   # overwritten in child classes
    state :pending
    state :actionable
    state :approved
  end

  belongs_to :proposal
  acts_as_list scope: :proposal
  validates :proposal, presence: true

  belongs_to :parent, class_name: 'Approval'
  has_many :child_approvals, class_name: 'Approval', foreign_key: 'parent_id'

  scope :individual, -> { where(type: 'Approvals::Individual') }


  self.statuses.each do |status|
    scope status, -> { where(status: status) }
  end
  scope :non_pending, -> { where.not(status: 'pending') }

  default_scope { order('position ASC') }

  def notify_parent_approved
    if self.parent
      self.parent.child_approved!(self)
    else
      self.proposal.approve!
    end
  end

  def children_approved?
    self.child_approvals.where.not(status: "approved").empty?
  end

  def pre_order_tree_traversal
    [self] + self.child_approvals.flat_map(&:pre_order_tree_traversal)
  end
end
