class ObservationsController < ApplicationController
  # TODO authenticate_user!
  # TODO authorize

  def index
    @proposal = self.find_proposal
    @observer = User.new
    @observation = Observation.new(user: @observer, proposal: @proposal)
  end

  def create
    proposal = self.find_proposal
    proposal.add_observer(params[:observation][:user][:email_address])
    redirect_to proposal_observations_path(proposal)
  end


  protected

  def find_proposal
    Proposal.find(params[:proposal_id])
  end
end