# Authentication System

This lode documents Fizzy's authentication architecture, including the simplified auto-authentication for local use and the original magic link system.

## Current System: Auto-Authentication

The authentication has been simplified to automatically create accounts and sessions on first visit, requiring no sign-up or login.

### How It Works

1. **First Visit Flow**:
   - User visits any URL without a session cookie
   - `AutoSetup` service creates (or finds) default Identity, Account, User, and Session
   - Session cookie is set automatically
   - User is redirected to account-scoped URL (e.g., `/0000001/`)

2. **Subsequent Visits**:
   - Existing session cookie is validated
   - User continues with their existing session

3. **Logout Behavior**:
   - Session is destroyed
   - New session is immediately created
   - User is redirected back to their workspace (no login prompt)

### Default Values

| Entity | Default Value |
|--------|---------------|
| Email | `local@localhost` |
| User Name | `Local User` |
| Account Name | `My Workspace` |

### Key Files

| File | Purpose |
|------|---------|
| `app/models/auto_setup.rb` | Service that orchestrates auto-creation of identity, account, user, and session |
| `app/controllers/concerns/authentication.rb` | Core authentication logic, `require_authentication` triggers auto-setup |
| `app/controllers/concerns/authorization.rb` | Auto-joins user to account if needed |
| `app/controllers/sessions_controller.rb` | Redirects login/signup to auto-setup landing |
| `app/controllers/sessions/menus_controller.rb` | Always redirects to first account |

### AutoSetup Service

```ruby
# app/models/auto_setup.rb
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
```

### Authentication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    User Visits Any URL                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              require_account (before_action)                 │
│   If no Current.account → AutoSetup → redirect to account   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│            require_authentication (before_action)            │
│   resume_session (from cookie) OR auto_create_and_resume    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│            ensure_can_access_account (before_action)         │
│   If no user in account → auto-join via Identity.join       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Controller Action Runs                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Original System: Magic Link Authentication (Preserved)

The original authentication system used passwordless magic links. All models and infrastructure remain in place for potential reversion.

### Original Flow

1. **Sign-Up**:
   - User enters email at `/signup`
   - Identity created (or found), magic link sent via email
   - User enters 6-digit code from email
   - Session created, user redirected to name entry
   - Account and owner User created on completion

2. **Login**:
   - User enters email at `/session`
   - Magic link sent to existing Identity
   - User enters 6-digit code
   - Session created, redirected to app

### Models (Unchanged)

**Identity** (`app/models/identity.rb`):
- Represents a unique email address
- Can have Users in multiple Accounts
- Has sessions and magic_links associations
- `send_magic_link(for:)` - generates and emails magic link
- `join(account, **attributes)` - creates User in account (via `Identity::Joinable`)

**Session** (`app/models/session.rb`):
- Belongs to Identity
- Tracks user_agent and ip_address
- Cookie uses signed_id for secure identification

**MagicLink** (`app/models/magic_link.rb`):
- 6-digit alphanumeric code (excludes I, L, O to avoid confusion)
- 15-minute expiration
- Purposes: `:sign_in`, `:sign_up`
- `consume(code)` - validates and destroys link

**User** (`app/models/user.rb`):
- Belongs to Account and Identity (identity optional)
- Roles: owner, admin, member, system
- Has many associations for comments, cards, etc.

**Account** (`app/models/account.rb`):
- Multi-tenant container
- `create_with_owner(account:, owner:)` - creates account with system and owner users

### Original Controllers (Now Bypassed)

- `SignupsController` - email entry for new users
- `Signups::CompletionsController` - name entry after magic link
- `Sessions::MagicLinksController` - magic link code verification

### Original Routes (Still Defined)

```ruby
resource :session do
  scope module: :sessions do
    resources :transfers
    resource :magic_link
    resource :menu
  end
end

resource :signup, only: [:new, :create] do
  collection do
    scope module: :signups do
      resource :completion, only: [:new, :create]
    end
  end
end
```

---

## Reversion Guide

To restore original magic link authentication:

1. **Delete** `app/models/auto_setup.rb`

2. **Revert** `app/controllers/concerns/authentication.rb`:
   ```ruby
   # Change back to:
   def require_authentication
     resume_session || request_authentication
   end

   def require_account
     unless Current.account.present?
       redirect_to session_menu_url(script_name: nil)
     end
   end

   def request_authentication
     if Current.account.present?
       session[:return_to_after_authenticating] = request.url
     end
     redirect_to_login_url
   end
   ```

3. **Revert** `app/controllers/concerns/authorization.rb`:
   ```ruby
   # Remove auto-join logic from ensure_can_access_account
   def ensure_can_access_account
     redirect_to session_menu_url(script_name: nil) if Current.user.blank? || !Current.user.active?
   end
   ```

4. **Revert** `app/controllers/sessions_controller.rb` to original magic link flow

5. **Revert** `app/controllers/sessions/menus_controller.rb` to show account menu

---

## Production Configuration for Local Use

The production environment has been configured to work locally without SSL:

**File:** `config/environments/production.rb`

### SSL Disabled
```ruby
config.assume_ssl = false
config.force_ssl = false
```

### Allowed Hosts
```ruby
config.hosts = %w[localhost 127.0.0.1]
```

### URL Generation
Redirects use `_path` helpers (relative URLs) instead of `_url` helpers (absolute URLs) to avoid port/host issues when running behind proxies.

---

## Docker Deployment

### Architecture
The production Docker container uses:
- **Thruster** (port 80) - HTTP proxy, handles static assets and compression
- **Puma** (port 3000) - Rails application server

Thruster listens on port 80 and forwards requests to Puma on port 3000 internally.

### Port Mapping
Map the external port to container port 80:

```bash
# docker run
docker run -d -p 9461:80 fizzy

# docker-compose.yml
services:
  fizzy:
    ports:
      - "9461:80"
```

This maps: `host:9461` → `container:80 (Thruster)` → `container:3000 (Puma)`

### Important Notes
- **Do not change Puma's default port 3000** - Thruster expects it
- External port is configurable via Docker port mapping
- Internal ports (3000, 80) are only visible inside the container

---

## Design Decisions

### Hybrid Authentication (December 2024)

Authentication supports both auto-setup for web UI and bearer tokens for API:

```ruby
def require_authentication
  resume_session || authenticate_by_bearer_token || auto_create_and_resume_session
end
```

**Flow:**
1. `resume_session` - Check for session cookie (web users)
2. `authenticate_by_bearer_token` - Check for Bearer token (API users)
3. `auto_create_and_resume_session` - Fall back to auto-setup (new web users)

**Bearer token authentication:**
```ruby
def authenticate_by_bearer_token
  if request.authorization.to_s.include?("Bearer")
    authenticate_or_request_with_http_token do |token|
      if identity = Identity.find_by_permissable_access_token(token, method: request.method)
        Current.identity = identity
      end
    end
  end
end
```

**Key point:** API requests with different user tokens will create cards/comments under the correct user. Without bearer token auth, all API requests would use the auto-setup default user.

See `lode/local-development.md` for creating tokens via Rails console.

---

## Security Considerations

### Current System
- No password storage (no attack surface)
- Sessions use signed permanent cookies (httponly, same_site: lax)
- Single local user - appropriate for self-hosted/local deployments
- SSL disabled for local use
- No API tokens - reduces attack surface

### Original System (if restored)
- Magic links expire in 15 minutes
- Code generation excludes confusable characters
- Rate limiting on login/signup endpoints (10 requests per 3 minutes)
- Sessions track IP and user agent
