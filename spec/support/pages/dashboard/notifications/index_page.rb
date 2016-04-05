require 'rails_helper'

module Dashboard
  module Notifications
    class IndexPage < SitePrism::Page
      set_url '/dashboard/notifications'

      element :compose_button, 'button', text: 'Compose Message'

      element :mark_as_read_button, 'button', text: 'Mark as Read'
      element :mark_as_unread_button, 'button', text: 'Mark as Unread'

      element :search_field, "input[placeholder='Search']"

      element :view_inbox_button, 'button', text: 'Inbox'
      element :view_sent_button, 'button', text: 'Sent'

      element :select_all, 'input[name="btSelectAll"]'
      element :user_header, 'th', text: 'User'
      element :time_header, 'th', text: 'Time'
      sections :notifications, 'tbody tr' do
        element :select_checkbox, 'input[name="btSelectItem"]'
        element :checked_select_checkbox, 'input[name="btSelectItem"]:checked'
        element :unchecked_select_checkbox, 'input[name="btSelectItem"]:not(:checked)'
      end

      section :send_notification_modal, '.modal', text: "Send Notification" do
        # element :select_user, :field, "Select User:"        -- label not associated correctly
        element :select_user, "input[placeholder='Search for a User']"
        elements :search_results, ".tt-selectable"
        element :subject_line, "input[placeholder='Subject']"
        element :message_box, "textarea[placeholder='Please enter message text here...']"
        element :send_button, "button", text: "Send"
      end
    end
  end
end
