# -*- coding: utf-8 -*-
# mailer_helper.rb
  class CommunicartMailer < ActionMailer::Base
  layout 'communicart_base'
  helper_method:set_attachments 


  def set_attachments(cart)
    if cart.all_approvals_received?
      attachments['Communicart' + cart.name + '.details.csv'] = cart.create_items_csv
      attachments['Communicart' + cart.name + '.comments.csv'] = cart.create_comments_csv
      attachments['Communicart' + cart.name + '.approvals.csv'] = cart.create_approvals_csv
    end
  end


   def cart_notification_email(email, cart, approval)
    @url = ENV['NOTIFICATION_URL']
    @cart = cart.decorate
    @approval = approval
    @token = ApiToken.where(user_id: @approval.user_id).where(cart_id: @cart.id).last
    @cart_template = cart.cart_template_name
    @prefix_template = cart.prefix_template_name

    set_attachments(cart)

    approval_format = Settings.email_title_for_approval_request_format
    mail(
         to: email,
         subject: approval_format % [ cart.requester.full_name,cart.external_id],
         from: ENV['NOTIFICATION_FROM_EMAIL']
         )
  end

  def cart_observer_email(email, cart)
    @url = ENV['NOTIFICATION_URL']
    @cart = cart.decorate
    @cart_template = cart.cart_template_name
    @prefix_template = cart.prefix_template_name

    set_attachments(cart)

    approval_format = Settings.email_title_for_approval_request_format
    mail(
         to: email,
         subject: approval_format % [ cart.requester.full_name,cart.external_id],
         from: ENV['NOTIFICATION_FROM_EMAIL']
         )
  end

  def approval_reply_received_email(analysis, cart)
# This is a shared constant between C2 and Mario, which should be moved to our
# YAML file
    @approval = analysis["approve"] == "APPROVE" ? "approved" : "rejected"
    @approval_reply = analysis
    @cart = cart.decorate
    @cart_template = cart.cart_template_name
    to_address = cart.requester.email_address
    #TODO: Handle carts without approval groups (only emails passed)
    #TODO: Add a specific 'rejection' text block for the requester

    set_attachments(cart)

    @url = ENV['NOTIFICATION_URL']
    mail(
         to: to_address,
         subject: "User #{analysis['fromAddress']} has #{@approval} cart ##{analysis['cartNumber']}",
         from: ENV['NOTIFICATION_FROM_EMAIL']
         )
  end

  def rejection_update_email(params, cart)
    # TODO: Fill out the content of this email to the approvers
  end

  def comment_added_email(comment, to_email)
    @comment_text = comment.comment_text
    @cart_item = comment.commentable

    mail(
         to: to_email,
         subject: "A comment has been added to cart item '#{@cart_item.description}'",
         from: ENV['NOTIFICATION_FROM_EMAIL']
         )
  end

end

