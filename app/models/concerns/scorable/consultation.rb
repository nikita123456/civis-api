module Scorable
  module Consultation
    extend ActiveSupport::Concern
    include Scorable

    included do 

	    before_save :add_consultation_created_points, if: :status_changed? if respond_to? :before_save

	    def add_consultation_created_points
	    	self.created_by.add_points(:consultation_created) if ( self.status_changed?(from: "submitted", to: "published") && self.public_consultation? && !self.created_by.admin? && self.created_by.city.present?)
	    end
	  end
  end
end
