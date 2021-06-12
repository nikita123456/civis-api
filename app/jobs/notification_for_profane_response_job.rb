class NotificationForProfaneResponseJob < ApplicationJob
    queue_as :default
  
    def perform(consultation)
        ::User.where(role: [:admin, :moderator]).each do |user|
        begin
            UserMailer.notification_for_profane_response(user_id, consultation_id).deliver_now
        rescue
          puts "Failed to deliver email for User - #{user.id}"
        end
      end
    end
  end
  