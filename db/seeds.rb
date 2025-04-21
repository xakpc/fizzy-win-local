raise "Seeding is just for development" unless Rails.env.development?

# Seed DSL
def seed_account(name)
  print "  #{name}…"
  elapsed = Benchmark.realtime { require_relative name }
  puts " #{elapsed.round(2)} sec"
end

def create_tenant(name)
  ApplicationRecord.destroy_tenant name
  ApplicationRecord.create_tenant name
  ApplicationRecord.current_tenant = name
end

def create_first_run(name, email_address, password: "secret123456")
  FirstRun.create!(name:, email_address:, password:)
end

def login_as(user)
  Current.session = user.sessions.create
end

def create_user(name, email_address, password: "secret123456")
  User.create!(name:, email_address:, password:)
end

def create_collection(name, creator: Current.user, all_access: true, access_to: [])
  Collection.create!(name:, creator:, all_access:).tap { it.accesses.grant_to(access_to) }
end

def create_card(title, collection:, description: nil, status: :published, creator: Current.user)
  collection.cards.create!(title:, creator:, status:).tap do |card|
    card.capture(Comment.new(body: description)) if description
  end
end

# Seed accounts
seed_account "37signals"
seed_account "honcho"
seed_account "first-run"
