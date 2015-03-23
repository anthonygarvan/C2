describe Ncr::WorkOrder do
  describe 'fields_for_display' do
    it "shows BA61 fields" do
      wo = Ncr::WorkOrder.new(
        amount: 1000, expense_type: "BA61", vendor: "Some Vend", 
        not_to_exceed: false, emergency: true, rwa_number: "RWWAAA #",
        building_number: Ncr::BUILDING_NUMBERS[0],
        office: Ncr::OFFICES[0])
      expect(wo.fields_for_display.sort).to eq([
        ["Amount", 1000],
        ["Building number", Ncr::BUILDING_NUMBERS[0]],
        ["Emergency", true],
        ["Expense type", "BA61"],
        ["Not to exceed", false],
        ["Office", Ncr::OFFICES[0]],
        # No RWA Number
        ["Vendor", "Some Vend"]
      ])
    end
    it "shows BA80 fields" do
      wo = Ncr::WorkOrder.new(
        amount: 1000, expense_type: "BA80", vendor: "Some Vend", 
        not_to_exceed: false, emergency: true, rwa_number: "RWWAAA #",
        building_number: Ncr::BUILDING_NUMBERS[0],
        office: Ncr::OFFICES[0])
      expect(wo.fields_for_display.sort).to eq([
        ["Amount", 1000],
        ["Building number", Ncr::BUILDING_NUMBERS[0]],
        # No Emergency
        ["Expense type", "BA80"],
        ["Not to exceed", false],
        ["Office", Ncr::OFFICES[0]],
        ["RWA Number", "RWWAAA #"],
        ["Vendor", "Some Vend"]
      ])
    end
  end

  describe '#add_approvals_on' do
    let (:cart) { FactoryGirl.create(:cart) }
    it "creates approvers when not an emergency" do
      form = FactoryGirl.build(:ncr_work_order, expense_type: 'BA61')
      form.add_approvals_on(cart, 'bob@example.com')
      expect(cart.approvals.observing.length).to eq(0)
      expect(cart.approvals.approvable.length).to eq(3)
      cart.reload
      expect(cart.approved?).to eq(false)
    end
    it "creates observers when in an emergency" do
      form = FactoryGirl.build(:ncr_work_order, expense_type: 'BA61',
                               emergency: true)
      form.add_approvals_on(cart, 'bob@example.com')
      expect(cart.approvals.observing.length).to eq(3)
      expect(cart.approvals.approvable.length).to eq(0)
      cart.clear_association_cache
      expect(cart.approved?).to eq(true)
    end
  end
  describe '#create_cart' do
    let(:requester) { FactoryGirl.create(:user) }
    def approver_emails(cart)
      approvals = cart.ordered_approvals
      approvals.map {|a| a.user.email_address }
    end

    it "adds the budget approver for a BA80 request" do
      form = FactoryGirl.create(:ncr_work_order, expense_type: 'BA80')
      cart = form.create_cart('aaa@example.com', 'Desc1', requester)

      expect(cart.name).to eq('Desc1')
      expect(cart.requester).to eq(requester)
      expect(approver_emails(cart)).to eq(%w(
        aaa@example.com
        communicart.budget.approver@gmail.com
      ))
    end

    it "adds the two approvers for a BA61 request" do
      form = FactoryGirl.build(:ncr_work_order, expense_type: 'BA61')
      cart = form.create_cart('bbb@example.com', 'Desc2', requester)

      expect(cart.name).to eq('Desc2')
      expect(cart.requester).to eq(requester)
      expect(approver_emails(cart)).to eq(%w(
        bbb@example.com
        communicart.budget.approver@gmail.com
        communicart.ofm.approver@gmail.com
      ))
    end
  end
  describe '#total_price' do
    let (:work_order) { FactoryGirl.create(:ncr_work_order, amount: 45.36)}
    it 'gets price from amount field' do
      expect(work_order.total_price).to eq(45.36)
    end
  end
end
