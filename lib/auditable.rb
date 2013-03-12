module Auditable
  module Acts #:nodoc:
    module Audited #:nodoc:
      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end
      module ClassMethods
        def acts_as_auditable
          include Auditable::Acts::Audited::InstanceMethods
          class_eval do
            has_many :audit_logs, :as => :auditable, :order => 'audit_logs.created_on desc'
          end
        end

        def permanently_delete_soft_deleted(time)
          destroy_all(['status = ? and updated_on <= ?', Contest::STATUS_DELETED, time])
        end
      end

      module InstanceMethods
        # Creates a new log message
        # activity - The activity performed 
        # user - The user who performed the activity
        def log(activity, user, region_id = nil)
          audit_logs.create(:activity => activity, :user_id => user.id, :region_id => region_id)
        end

        def soft_delete(user)
          if self.is_a?(Entry) && self.live?
            # live entries cannot be soft_delete'd cos it leads to complications
            # in the faceoff game play. 
            self.destroy
            log(AuditLog::DESTROYED, user)
          else  
            update_attribute(:status, Contest::STATUS_DELETED)
            log(AuditLog::DELETED, user)
            if self.is_a?(Entry)
                self.questions.each {|q| q.soft_delete(user) }
            end  
          end
        end

      end

    end
  end
end
