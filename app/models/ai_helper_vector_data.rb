class AiHelperVectorData < ApplicationRecord
  validates :object_id, presence: true
  validates :index, presence: true
  validates :uuid, presence: true
end
