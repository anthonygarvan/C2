describe "Version check" do
  let(:proposal) { FactoryGirl.create(:proposal, :with_parallel_approvers) }

  it "occurs if the proposal is modified in after seeing the profile page" do
    login_as(proposal.approvers.first)
    visit "/proposals/#{proposal.id}"

    sleep 1.second  # wait to get a new update time
    proposal.touch

    click_on 'Approve'

    expect(page).to have_content("This request has recently changed.")
    expect(current_path).to eq("/proposals/#{proposal.id}")
  end
end
