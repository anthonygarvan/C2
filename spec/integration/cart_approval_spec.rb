require 'spec_helper'

describe 'Approving a cart with multiple approvers' do

  let(:approval_params) {
      '{
      "cartNumber": "10203040",
      "category": "approvalreply",
      "attention": "",
      "fromAddress": "approver1@some-dot-gov.gov",
      "gsaUserName": "",
      "gsaUsername": null,
      "date": "Sun, 13 Apr 2014 18:06:15 -0400",
      "approve": "APPROVE",
      "disapprove": null,
      "comment" : "spudcomment"
      }'
    }

  before do
    ENV['NOTIFICATION_FROM_EMAIL'] = 'sender@some-dot_gov.gov'

    @json_approval_params = JSON.parse(approval_params)

    approval_group = ApprovalGroup.create(name: "A Testworthy Approval Group")

    approval_group.requester = Requester.create(email_address: 'test-requestser@some-dot-gov.gov')

    cart = Cart.new(
                    name: 'My Wonderfully Awesome Communicart',
                    status: 'pending',
                    external_id: '10203040'
                    )

    cart.approval_group = approval_group

    # Want to test by adding some traits in here....
    cart.cart_items << FactoryGirl.create(:cart_item)
    cart.cart_items[0].cart_item_traits << FactoryGirl.create(:cart_item_trait)
    cart.cart_items[0].cart_item_traits << FactoryGirl.create(:cart_item_trait,name: "feature",value: "bpa")
    cart.cart_items[0].cart_item_traits << FactoryGirl.create(:cart_item_trait,name: "socio",value: "w")
    cart.cart_items[0].cart_item_traits << FactoryGirl.create(:cart_item_trait,name: "socio",value: "v")

    (1..3).each do |num|
      email = "approver#{num}@some-dot-gov.gov"

      user = FactoryGirl.create(:user, email_address: email)
      approval_group.users << user
      cart.approvals << Approval.create!(user_id: user.id)
    end

    cart.save

  end

  it 'updates the cart and approval records as expected' do
    # Remove stub to view email layout in development through letter_opener
    # CommunicartMailer.stub_chain(:approval_reply_received_email, :deliver)

    Cart.count.should == 1
    User.count.should == 3
    expect(Cart.first.approvals.count).to eq 3
    expect(Cart.first.approvals.where(status: 'approved').count).to eq 0

    post 'approval_reply_received', @json_approval_params

    expect(Cart.first.approvals.count).to eq 3
    expect(Cart.first.approvals.where(status: 'approved').count).to eq 1

    @json_approval_params["fromAddress"] = "approver2@some-dot-gov.gov"
    post 'approval_reply_received', @json_approval_params

    expect(Cart.first.approvals.count).to eq 3
    expect(Cart.first.approvals.where(status: 'approved').count).to eq 2

    @json_approval_params["fromAddress"] = "approver3@some-dot-gov.gov"
    post 'approval_reply_received', @json_approval_params

    expect(Cart.first.approvals.count).to eq 3
    expect(Cart.first.approvals.where(status: 'approved').count).to eq 3
    expect(Cart.first.comments.first.comment_text).to eq "spudcomment"
    expect(ApproverComment.count).to eq 3

  end
end
