json.extract! account, :id, :name, :plan_id, :active, :description, :created_at, :updated_at
json.url account_url(account, format: :json)
