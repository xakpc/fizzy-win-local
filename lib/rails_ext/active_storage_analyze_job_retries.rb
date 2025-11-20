# Avoid sporadic ActiveStorage::FileNotFoundError errors
#
# Our direct-uploads aren't really direct. They first get buffered by CloudFlare
# and then get sent to our storage servers. This can lead to situations where
# a form was submitted, and ActiveStorage::Attachment created, and an
# AnalyzeJob enqueued, but the file associated with the Blob doesn't yet exist
# in our storage service.
#
# A simple olution ot this problem is just to retry the job a few times with
# some backoff.
#
# Discussion: https://app.fizzy.do/5986089/cards/3056
module ActiveStorageAnalyzeJobRetires
  extend ActiveSupport::Concern

  included do
    retry_on ActiveStorage::FileNotFoundError, attempts: 15, wait: 2.seconds
  end
end

ActiveSupport.on_load :active_storage_blob do
  ActiveStorage::AnalyzeJob.prepend ActiveStorageAnalyzeJobRetires
end
