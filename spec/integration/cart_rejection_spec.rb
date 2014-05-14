require 'spec_helper'

describe 'Rejecting a cart with multiple approvers' do

  #TODO: approve/disapprove/comment > humanResponseText
  let(:rejection_params) {
      '{
      "cartNumber": "10203040",
      "category": "approvalreply",
      "attention": "",
      "fromAddress": "approver1@some-dot-gov.gov",
      "gsaUserName": "",
      "gsaUsername": null,
      "date": "Sun, 13 Apr 2014 18:06:15 -0400",
      "approve": null,
      "disapprove": "REJECT",
      "humanResponseText": "",
      "comment" : "Please order 500 highlighters instead of 300 highlighters"
      }'
    }

  let(:params_request_1) {
  '{
      "cartName": "",
      "approvalGroup": "updatingRejectedApprovalGroup",
      "cartNumber": "10203040",
      "category": "initiation",
      "email": "test.email@some-dot-gov.gov",
      "fromAddress": "approver1@some-dot-gov.gov",
      "gsaUserName": "",
      "initiationComment": "\r\n\r\nHi, this is a comment, I hope it works!\r\nThis is the second line of the comment.",
      "cartItems": [
        {
          "vendor": "DOCUMENT IMAGING DIMENSIONS, INC.",
          "description": "ROUND RING VIEW BINDER WITH INTERIOR POC",
          "url": "/advantage/catalog/product_detail.do?&oid=704213980&baseOid=&bpaNumber=GS-02F-XA002",
          "notes": "",
          "qty": "24",
          "details": "Direct Delivery 3-4 days delivered ARO",
          "socio": [],
          "partNumber": "7510-01-519-4381",
          "price": "$2.46",
          "features": [
              "sale"
          ]
        },
        {
          "vendor": "OFFICE DEPOT",
          "description": "PEN,ROLLER,GELINK,G-2,X-FINE",
          "url": "/advantage/catalog/product_detail.do?&oid=703389586&baseOid=&bpaNumber=GS-02F-XA009",
          "notes": "",
          "qty": "5",
          "details": "Direct Delivery 3-4 days delivered ARO",
          "socio": ["s","w"],
          "partNumber": "PIL31003",
          "price": "$10.29",
          "features": []
        },
        {
          "vendor": "METRO OFFICE PRODUCTS",
          "description": "PAPER,LEDGER,11X8.5",
          "url": "/advantage/catalog/product_detail.do?&oid=681115589&baseOid=&bpaNumber=GS-02F-XA004",
          "notes": "",
          "qty": "3",
          "details": "Direct Delivery 3-4 days delivered ARO",
          "socio": ["s"],
          "partNumber": "WLJ90310",
          "price": "$32.67",
          "features": []
        }
      ]
    }'
  }



  let(:approver) { FactoryGirl.create(:approver) }

  before do
    ENV['NOTIFICATION_FROM_EMAIL'] = 'sender@some-dot_gov.gov'

    @json_rejection_params = JSON.parse(rejection_params)

    approval_group = ApprovalGroup.create(name: "updatingRejectedApprovalGroup")
    approval_group.requester = Requester.create(email_address: 'test-requestser@some-dot-gov.gov')

    cart = Cart.new(
                    name: '10203040',
                    status: 'pending',
                    external_id: '10203040'
                    )

    cart.approval_group = approval_group
    cart.cart_items << FactoryGirl.create(:cart_item)

    (1..3).each do |num|
      email = "approver#{num}@some-dot-gov.gov"

      user = FactoryGirl.create(:user, email_address: email)
      approval_group.users << user
      cart.approvals << Approval.create!(user_id: user.id)
    end

    cart.save

  end

  # context 'User corrects the rejected mistake'

  it 'updates the cart and approver records as expected' do
    # Remove stub to view email layout in development through letter_opener
    # CommunicartMailer.stub_chain(:rejection_reply_received_email, :deliver)

    Cart.count.should == 1
    User.count.should == 3

    cart = Cart.first
    expect(cart.external_id).to eq 10203040
    expect(cart.approvals.count).to eq 3
    expect(cart.approvals.where(status: 'approved').count).to eq 0

    post 'approval_reply_received', @json_rejection_params

    expect(cart.approvals.count).to eq 3
    expect(cart.approvals.where(status: 'approved').count).to eq 0
    expect(cart.approvals.where(status: 'rejected').count).to eq 1
    expect(cart.reload.status).to eq 'rejected'

    #-- A cart with an approval group
    # A mailer sends out with the current state of things (rejected) to the requester
    # A mailer sends out an update to the approvers
    # User corrects the mistake and resubmits

    @json_params_1 = JSON.parse(params_request_1)
    post 'send_cart', @json_params_1

    expect(Cart.count).to eq 2
    updated_cart = Cart.last
    expect(updated_cart.status).to eq 'pending'

    # Cart with the same external ID should be associated with a new set of users with approvals in status 'pending'
    expect(updated_cart.external_id).to eq 10203040
    expect(Cart.count).to eq 2
    expect(updated_cart.approvals.count).to eq 3

    # A new set of emails is sent to everyone on the list

    # If they respond to a previous one, they get an email that it has expired and to respond to 'this one'

    # Start the web interface that allows people to just do everything in a web page experience


  end
end
