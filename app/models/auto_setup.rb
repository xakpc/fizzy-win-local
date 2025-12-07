class AutoSetup
  DEFAULT_EMAIL = "local@localhost"
  DEFAULT_NAME = "Local User"
  DEFAULT_ACCOUNT_NAME = "My Workspace"

  def self.ensure_ready!(request:)
    new.ensure_ready!(request: request)
  end

  def ensure_ready!(request:)
    @identity = Identity.find_or_create_by!(email_address: DEFAULT_EMAIL)
    @account = find_or_create_account
    @session = @identity.sessions.first_or_create!(
      user_agent: request.user_agent,
      ip_address: request.remote_ip
    )
    self
  end

  attr_reader :identity, :account, :session

  private

  def find_or_create_account
    @identity.accounts.first || create_account_with_owner
  end

  def create_account_with_owner
    Account.create_with_owner(
      account: { name: DEFAULT_ACCOUNT_NAME },
      owner: { name: DEFAULT_NAME, identity: @identity }
    )
  end
end
