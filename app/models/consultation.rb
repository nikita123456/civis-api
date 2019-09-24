class Consultation < ApplicationRecord
  include SpotlightSearch
	include Paginator
  include Scorable::Consultation
  has_rich_text :summary

  belongs_to :ministry
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User', optional: true
  has_many :responses, class_name: "ConsultationResponse"
  has_many :shared_responses, -> { shared }, class_name: "ConsultationResponse"
  has_many :anonymous_responses, -> { anonymous }, class_name: "ConsultationResponse"
  export_columns enabled: true, except: [:response_token, :url]
  enum status: { submitted: 0, published: 1, rejected: 2, expired: 3 }

  before_commit :update_reading_time
  after_commit :notify_goverment_email

  scope :status_filter, lambda { |status|
    return all unless status.present?
    where(status: status)
  }

  scope :ministry_filter, lambda { |ministry_id|
    return all unless ministry_id.present?
    where(ministry_id: ministry_id)
  }

  scope :featured_filter, lambda { |featured|
    return all unless featured.present?
    where(is_featured: featured)
  }

  scope :search_query, lambda { |query = nil|
    return nil unless query
    where('title ILIKE (?)', "%#{query}%")
  }

  scope :sort_records, lambda { |sort, sort_direction = "asc"|
    return nil if sort.blank?
    order("#{sort} #{sort_direction}")
  }

  def publish
  	self.status = :published
    self.response_token = SecureRandom.uuid
  	self.published_at = DateTime.now
  	self.save!
    NotifyNewConsultationEmailJob.perform_later(self)
    NotifyPublishedConsultationEmailJob.perform_later(self) if self.created_by.citizen?
  end

  def reject
  	self.update(status: :rejected)
  end

  def expire
  	self.update(status: :expired)
  end

  def responded_on(user = Current.user)
    user_response = self.responses.find_by(user: user)
    return nil if user_response.nil?
    return user_response.created_at
  end

  def satisfaction_rating_distribution
    self.responses.group(:satisfaction_rating).distinct.count(:satisfaction_rating)
  end

  def featured
    self.update(is_featured: true)
  end

  def unfeatured
    self.update(is_featured: false)
  end

  def update_reading_time
    if self.summary.saved_change_to_body?
      total_word_count = self.summary.body.to_plain_text.length
      time = total_word_count.to_f / 200
      time_with_divmod = time.divmod 1
      array = [time_with_divmod[0].to_i, time_with_divmod[1].round(2) * 0.60 ]
      if array[1] > 0.30
        total_reading_time = array[0] + 1
      else
        total_reading_time = array[0]
      end
      self.reading_time = total_reading_time
      self.save
    end
  end

  def days_left
    (response_deadline.to_date - Date.current).to_i if (response_deadline && published_at)
  end

  def feedback_url
    feedback_url = URI::HTTP.build(Rails.application.config.client_url.merge!({ path: '/consultations/' + "#{self.id}" +'/read' } ))
    feedback_url.to_s
  end

  def response_url
    response_url = URI::HTTP.build(Rails.application.config.client_url.merge!({ path: '/consultations/' + "#{self.id}" +'/summary', query: "response_token=#{self.response_token}" } ))
    response_url.to_s
  end

  def notify_goverment_email
    if self.status_changed? && self.expired?
      NotifyExpiredConsultationEmailJob.perform_later(self.ministry.poc_email_primary, self) if self.ministry.poc_email_primary
      NotifyExpiredConsultationEmailJob.perform_later(self.ministry.poc_email_secondary, self) if self.ministry.poc_email_secondary
    end
  end
end
