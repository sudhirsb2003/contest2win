# When models with files stored in S3 are deleted, 
# the associated files are not deleted from S3 immediately
# for performance reasons. These files are logged into
# pending_delettions and deleted via a batch operation
# that runs periodically
class PendingDeletion < ActiveRecord::Base
  def self.purge_s3
    s3 = RightAws::S3.new(FileColumn::S3FileColumnExtension::Config::s3_access_key_id, FileColumn::S3FileColumnExtension::Config::s3_secret_access_key)
    bucket = s3.bucket(FileColumn::S3FileColumnExtension::Config::s3_bucket_name, true, 'public-read')
    all.each do |pd|
      bucket.delete_folder(pd.key) 
      pd.destroy
    end
  end
end
