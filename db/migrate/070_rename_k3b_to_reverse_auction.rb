class RenameK3bToReverseAuction < ActiveRecord::Migration
  def self.up
    execute %{alter table bids rename column k3b_id to reverse_auction_id}
    execute %{update contests set type = 'ReverseAuction' where type = 'K3b'}
  end

  def self.down
    execute %{alter table bids rename column reverse_auction_id to k3b_id}
  end
end
