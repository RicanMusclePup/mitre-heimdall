class Ref < ApplicationRecord
  belongs_to :control

  def to_jbuilder
    Jbuilder.new do |json|
      json.extract! self, :ref, :url, :uri
    end
  end

  def as_json
    to_jbuilder.attributes!
  end

  def to_json(*_args)
    to_jbuilder.target!
  end
end
