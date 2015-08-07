# This is a temporary way to handle a notification preference
# that will eventually be managed at the user level
# https://www.pivotaltracker.com/story/show/87656734

class NcrDispatcher < LinearDispatcher

  def requires_approval_notice?(approval)
    final_approval(approval.proposal) == approval
  end

  def final_approval(proposal)
    proposal.individual_approvals.last
  end

  # Notify approvers who have already approved that this proposal has been
  # modified. Also notify current approvers that the proposal has been updated
  def on_proposal_update(proposal)
    proposal.individual_approvals.approved.each{|approval|
      CommunicartMailer.notification_for_subscriber(approval.user_email_address, proposal, "already_approved", approval).deliver_now
    }

    proposal.currently_awaiting_approvals.each{|approval|
      if approval.api_token   # Approver's been notified through some other means
        CommunicartMailer.actions_for_approver(approval.user_email_address, approval, "updated").deliver_now
      else
        approval.create_api_token!
        CommunicartMailer.actions_for_approver(approval.user_email_address, approval).deliver_now
      end
    }

    proposal.observers.each{|observer|
      if observer.role_on(proposal).active_observer?
        CommunicartMailer.notification_for_subscriber(observer.email_address, proposal, "updated").deliver_now
      end
    }
  end

  def on_approver_removal(proposal, approvers)
    approvers.each{|approver|
      CommunicartMailer.notification_for_subscriber(approver.email_address,proposal,"removed").deliver_now
    }
  end
end
