json.extract! user, :id, :account_id, :email, :name, :role, :active, :created_at, :updated_at
json.url user_url(user, format: :json)
