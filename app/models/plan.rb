# == Schema Information
#
# Table name: plans
#
#  id         :bigint           not null, primary key
#  name       :string
#  price      :integer
#  status     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Plan < ApplicationRecord
end
