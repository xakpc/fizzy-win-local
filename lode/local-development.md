# Local Development

This lode documents Fizzy-specific patterns for local development, including API usage, user management, and real-time features.

---

## API Usage

### JSON Suffix Required

All API endpoints require `.json` suffix. Without it, the server returns a 302 redirect.

```bash
# Wrong - returns 302 redirect
curl -H "Authorization: Bearer TOKEN" http://localhost:9461/0000001/boards

# Correct - returns JSON
curl -H "Authorization: Bearer TOKEN" http://localhost:9461/0000001/boards.json
```

### Authentication Header

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Accept: application/json" \
     http://localhost:9461/0000001/boards.json
```

---

## Access Tokens

Access tokens belong to **Identity**, not User:

```ruby
# Model hierarchy
Identity
  └── has_many :access_tokens  # Identity::AccessToken
  └── has_many :users
```

### Token Permissions

- `"read"` - read-only API access
- `"write"` - read and write API access

**Key file:** `app/models/identity/access_token.rb`

---

## User Management via Rails Console

Since login UI is removed, users and tokens must be created via Rails console:

```bash
docker exec -it fizzy bin/rails console
```

### Create a New User with API Access

```ruby
# 1. Create identity (unique email)
identity = Identity.create!(email_address: "newuser@localhost")

# 2. Find account
account = Account.first

# 3. Create user in account (must set verified_at!)
user = account.users.create!(
  identity: identity,
  name: "New User",
  role: "member",
  verified_at: Time.current  # Required!
)

# 4. Create access token for API
token = identity.access_tokens.create!(
  description: "API Access",
  permission: "write"
)

puts "Token: #{token.token}"
```

### User Verification

Users have a `verified_at` timestamp on the **User** model (not Identity) that must be set:

```ruby
user = User.find_by(name: "Some User")
user.update!(verified_at: Time.current)
```

### Create Token for Existing User

```ruby
identity = Identity.find_by(email_address: "existing@localhost")
token = identity.access_tokens.create!(description: "MCP", permission: "write")
puts "Token: #{token.token}"
```

### List Existing Data

```ruby
# All identities
Identity.pluck(:id, :email_address)

# All users in an account
Account.first.users.pluck(:id, :name, :role)

# All access tokens for an identity
Identity.find_by(email_address: "user@localhost")
        .access_tokens.pluck(:token, :description)
```

---

## Real-Time Updates (ActionCable)

### Technology: Solid Cable

Fizzy uses **Solid Cable** (database-backed, not Redis):

```yaml
# config/cable.yml
cable: &cable
  adapter: solid_cable
  connects_to:
    database:
      writing: cable
      reading: cable
  polling_interval: 0.1.seconds
  message_retention: 1.day
```

### WebSocket Endpoint

```
ws://localhost:9461/:account_slug/cable
```

### Self-Updates Not Broadcast

**Important:** WebSocket updates are NOT sent to the user who made the change.

- When you create/update/delete a card, you see the change immediately in UI
- WebSocket broadcasts go only to OTHER users viewing the same board
- This is intentional to avoid redundant updates

### Testing Real-Time Updates

To test WebSocket updates:
1. Create a second user (see above)
2. Open app in incognito window (gets new session)
3. Make changes in one window
4. Observe updates in the other window

### Broadcasting Mechanics

Fizzy uses Turbo's `broadcasts_refreshes` for real-time updates:

- **Card broadcasts:** `Card::Broadcastable` broadcasts to the card itself (`turbo_stream_from @card`)
- **Board broadcasts:** `Board::Broadcastable` broadcasts to the board (`turbo_stream_from @board`)

These broadcasts use `broadcast_refresh_later` internally, which enqueues a background job. The job must be processed for WebSocket updates to be sent.

### Docker and SolidQueue (Required for Real-Time Updates)

In production mode (Docker), Fizzy uses **SolidQueue** for background jobs:

```ruby
# config/environments/production.rb
config.active_job.queue_adapter = :solid_queue
```

**SolidQueue must be running** for real-time features to work, including:
- Cards appearing when created via API
- Board updates when cards are moved/edited
- Any `broadcasts_refreshes` callbacks

#### Why SolidQueue is disabled by default

In `config/puma.rb`:
```ruby
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]
```

It's opt-in because running the job worker inside Puma adds overhead. In hosted production, SolidQueue runs as a separate process. For local Docker, you must explicitly enable it.

#### Do you need SolidQueue for local dev?

**For single-user local dev, usually no.** Your own UI actions update immediately without WebSocket broadcasts.

Enable SolidQueue only when testing:
- Real-time updates across multiple user sessions
- Webhooks
- Email/push notifications
- Mentions processing
- Account data export

| Feature | Needs SolidQueue? |
|---------|-------------------|
| Your own UI actions | No |
| API calls (no UI open) | No |
| Real-time updates (multi-user) | Yes |
| Webhook delivery | Yes |
| Email notifications | Yes |
| Push notifications | Yes |

#### Enable SolidQueue in Docker

```bash
docker run -it --rm \
  -p 3000:80 \
  -v fizzy-storage:/rails/storage \
  -v fizzy-db:/rails/db \
  -e SECRET_KEY_BASE=$(openssl rand -hex 64) \
  -e RAILS_LOG_LEVEL=info \
  -e SOLID_QUEUE_IN_PUMA=1 \
  fizzy-local
```

Without `SOLID_QUEUE_IN_PUMA=1`, jobs are enqueued but never processed.

---

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| API returns 302 redirect | Missing `.json` suffix | Add `.json` to URL |
| API returns 406 Not Acceptable | Wrong URL format after redirect | Use `.json` suffix |
| User can't access features | `verified_at` not set | Set `user.update!(verified_at: Time.current)` |
| WebSocket not updating | Updates only go to OTHER users | Test with two different user sessions |
| Token creation fails | Identity not verified | Verify user first, token is on Identity |
| Real-time updates not working in Docker | SolidQueue not running | Add `-e SOLID_QUEUE_IN_PUMA=1` to docker run |
