# frozen_string_literal: true

RSpec.describe Qualification do
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
  end
end
