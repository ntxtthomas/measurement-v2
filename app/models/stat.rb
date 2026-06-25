class Stat < ApplicationRecord
    validates :key, presence: true, uniqueness:true

    scope :dashboard, -> {where(key: "dashboard")} 
end
