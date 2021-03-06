class ProposalPolicy
  include ExceptionPolicy

  def initialize(user, record)
    super(user, record)
    @proposal = record
  end

  def can_approve!
    approver! && pending_approval! && not_cancelled!
  end

  def can_edit!
    requester! && not_approved! && not_cancelled!
  end
  alias_method :can_update!, :can_edit!

  def can_show!
    check(self.visible_proposals.exists?(@proposal.id), "You are not allowed to see this proposal")
  end

  def can_create!
    # TODO restrict by client_slug
    true
  end
  alias_method :can_new!, :can_create!

  def can_cancel!
    requester! && not_cancelled!
  end
  alias_method :can_cancel_form!, :can_cancel!

  protected

  def restricted?
    ENV['RESTRICT_ACCESS'] == 'true'
  end

  def requester?
    @proposal.requester_id == @user.id
  end

  def requester!
    check(self.requester?, "You are not the requester")
  end

  def not_approved!
    check(!@proposal.approved?,
          "That proposal's already approved. New proposal?")
  end

  def not_cancelled!
    check(!@proposal.cancelled?, "Sorry, this proposal has been cancelled.")
  end

  def approver?
    @proposal.approvers.exists?(@user.id)
  end

  def delegate?
    @proposal.delegate?(@user)
  end

  def approver!
    check(self.approver? || self.delegate?,
          "Sorry, you're not an approver on this proposal")
  end

  def observer!
    check(@proposal.observers.include?(@user),
          "Sorry, you're not an observer on this proposal")
  end

  def pending_approver?
    @proposal.currently_awaiting_approvers.include?(@user)
  end

  def pending_delegate?
    ApprovalDelegate.where(assigner_id: @proposal.currently_awaiting_approvers, assignee: @user).exists?
  end

  def pending_approval!
    check(self.pending_approver? || self.pending_delegate?,
          "A response has already been logged a response for this proposal")
  end

  def visible_proposals
    ProposalPolicy::Scope.new(@user, Proposal).resolve
  end
end
