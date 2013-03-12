class DispatchSearch < ActiveRecord::BaseWithoutTable
  column :dispatch_id
  column :username
  column :email
  column :dispatch_status
  column :search_term
  column :search_by
  column :region_id
end

