require 'rails_helper'

RSpec.describe Circle, type: :model do

  context 'Evaluation imported' do
    let(:user) { FactoryBot.create(:user) }
    let(:circle) { FactoryBot.build(:circle) }
    let(:eval) { FactoryBot.create(:evaluation, created_by: user) }

    it 'get recents' do
      circle.evaluations << eval
      recents = circle.recents
      expect(recents).to_not be_empty
    end
  end
end
