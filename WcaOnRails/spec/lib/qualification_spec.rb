# frozen_string_literal: true

RSpec.describe Qualification do
  let(:user) { FactoryBot.create(:user_with_wca_id) }
  let(:first_competition) {
    FactoryBot.create(
        :competition,
        start_date: '2021-02-01',
        end_date: '2021-02-01')
  }
  let(:second_competition) {
    FactoryBot.create(
        :competition,
        start_date: '2021-03-01',
        end_date: '2021-03-02')
  }

  let!(:first_333_result) {
    FactoryBot.create(
        :result,
        personId: user.wca_id,
        competitionId: first_competition.id,
        eventId: '333',
        best: 1200,
        average: 1500)
  }
  let!(:second_333_result) {
    FactoryBot.create(
        :result,
        personId: user.wca_id,
        competitionId: second_competition.id,
        eventId: '333',
        best: 1100,
        average: 1200)
  }
  let!(:first_oh_result) {
    FactoryBot.create(
        :result,
        personId: user.wca_id,
        competitionId: first_competition.id,
        eventId: '333oh',
        best: -1,
        average: -1)
  }
  let!(:second_oh_result) {
    FactoryBot.create(
        :result,
        personId: user.wca_id,
        competitionId: second_competition.id,
        eventId: '333oh',
        best: 1700,
        average: 2000)
  }

  context "Ranking" do
    it "requires ranking" do
      input = {
        'type' => 'ranking',
        'when' => '2021-06-01'
      }
      model = Qualification.load(input)
      expect(model).to be_invalid
    end

    it "requires date" do
      input = {
        'type' => 'ranking',
        'ranking' => 50
      }
      model = Qualification.load(input)
      expect(model).to be_invalid
    end

    it "parses correctly" do
      input = {
        'type' => 'ranking',
        'when' => '2021-06-01',
        'ranking' => 50
      }
      model = Qualification.load(input)
      expect(model).to be_valid
    end

    it "requires a successful time" do
      p user
      input = {
        'type' => 'ranking',
        'when' => '2021-02-15',
        'ranking' => 50
      }
      model = Qualification.load(input)
      expect(model).to be_valid
      expect(model.met?(user, '333')).to be true
      expect(model.met?(user, '333oh')).to be false

      input = {
        'type' => 'ranking',
        'when' => '2021-03-15',
        'ranking' => 50
      }
      model = Qualification.load(input)
      expect(model).to be_valid
      expect(model.met?(user, '333')).to be true
      expect(model.met?(user, '333oh')).to be true
    end
  end

  context "Single" do
    it "requires single" do
      input = {
        'type' => 'single',
        'when' => '2021-06-01'
      }
      model = Qualification.load(input)
      expect(model).to be_invalid
    end

    it "requires date" do
      input = {
        'type' => 'single',
        'single' => 1000
      }
      model = Qualification.load(input)
      expect(model).to be_invalid
    end

    it "parses correctly" do
      input = {
        'type' => 'single',
        'when' => '2021-06-01',
        'single' => 1000
      }
      model = Qualification.load(input)
      expect(model).to be_valid
    end

    it "requires strictly less than" do
      input = {
        'type' => 'single',
        'when' => '2021-02-15',
        'single' => 1200
      }
      model = Qualification.load(input)
      expect(model).to be_valid
      expect(model.met?(user, '333')).to be false

      input = {
        'type' => 'single',
        'when' => '2021-02-15',
        'single' => 1201
      }
      model = Qualification.load(input)
      expect(model).to be_valid
      expect(model.met?(user, '333')).to be true
    end

    it "requires start date no later than" do
      input = {
        'type' => 'single',
        'when' => '2021-03-01',
        'single' => 1150
      }
      model = Qualification.load(input)
      expect(model).to be_valid
      expect(model.met?(user, '333')).to be true

      input = {
        'type' => 'single',
        'when' => '2021-02-28',
        'single' => 1150
      }
      model = Qualification.load(input)
      expect(model).to be_valid
      expect(model.met?(user, '333')).to be false
    end
  end

  context "Average" do
    it "requires average" do
      input = {
        'type' => 'average',
        'when' => '2021-06-01'
      }
      model = Qualification.load(input)
      expect(model).to be_invalid
    end

    it "requires date" do
      input = {
        'type' => 'average',
        'average' => 1000
      }
      model = Qualification.load(input)
      expect(model).to be_invalid
    end

    it "parses correctly" do
      input = {
        'type' => 'average',
        'when' => '2021-06-01',
        'average' => 1000
      }
      model = Qualification.load(input)
      expect(model).to be_valid
    end

    it "requires strictly less than" do
      input = {
        'type' => 'average',
        'when' => '2021-02-15',
        'average' => 1500
      }
      model = Qualification.load(input)
      expect(model).to be_valid
      expect(model.met?(user, '333')).to be false

      input = {
        'type' => 'average',
        'when' => '2021-02-15',
        'average' => 1501
      }
      model = Qualification.load(input)
      expect(model).to be_valid
      expect(model.met?(user, '333')).to be true
    end

    it "requires start date no later than" do
      input = {
        'type' => 'average',
        'when' => '2021-03-01',
        'average' => 2500
      }
      model = Qualification.load(input)
      expect(model).to be_valid
      expect(model.met?(user, '333oh')).to be true

      input = {
        'type' => 'average',
        'when' => '2021-02-28',
        'average' => 2500
      }
      model = Qualification.load(input)
      expect(model).to be_valid
      expect(model.met?(user, '333oh')).to be false
    end
  end
end
