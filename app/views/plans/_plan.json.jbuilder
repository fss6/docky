json.extract! plan, :id, :name, :price, :status, :created_at, :updated_at
json.url plan_url(plan, format: :json)
