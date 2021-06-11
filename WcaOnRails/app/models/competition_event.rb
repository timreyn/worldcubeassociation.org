# frozen_string_literal: true

class CompetitionEvent < ApplicationRecord
  belongs_to :competition
  belongs_to :event
  has_many :registration_competition_events, dependent: :destroy
  has_many :rounds, -> { order(:number) }, dependent: :destroy
  has_many :wcif_extensions, as: :extendable, dependent: :delete_all

  accepts_nested_attributes_for :rounds, allow_destroy: true

  validates_numericality_of :fee_lowest_denomination, greater_than_or_equal_to: 0
  monetize :fee_lowest_denomination,
           as: "fee",
           with_model_currency: :currency_code

  serialize :qualification, Qualification
  validates_associated :qualification

  validate do
    remaining_rounds = rounds.reject(&:marked_for_destruction?)
    numbers = remaining_rounds.map(&:number).sort
    if numbers != (1..remaining_rounds.length).to_a
      errors.add(:rounds, "#{numbers} is wrong")
    end
  end

  def currency_code
    competition&.currency_code
  end

  def has_fee?
    fee.nonzero?
  end

  def event
    Event.c_find(event_id)
  end

  def qualification_to_s
    qualification&.to_s(self)
  end

  def to_wcif
    {
      "id" => self.event.id,
      "rounds" => self.rounds.map(&:to_wcif),
      "extensions" => wcif_extensions.map(&:to_wcif),
      "qualification" => qualification&.to_wcif,
    }
  end

  def load_wcif!(wcif)
    if self.rounds.pluck(:old_type).compact.any?
      raise WcaExceptions::BadApiParameter.new(
        "Cannot edit rounds for a competition which has qualification rounds or b-finals. Please contact WRT or WST if you need to make change to this competition.",
      )
    end
    self.rounds.destroy_all!
    total_rounds = wcif["rounds"].size
    wcif["rounds"].each_with_index do |wcif_round, index|
      round = self.rounds.create!(Round.wcif_to_round_attributes(self.event, wcif_round, index+1, total_rounds))
      WcifExtension.update_wcif_extensions!(round, wcif_round["extensions"]) if wcif_round["extensions"]
    end
    WcifExtension.update_wcif_extensions!(self, wcif["extensions"]) if wcif["extensions"]
    self.qualification = Qualification.load(wcif["qualification"])
    self.save
  end

  def self.wcif_json_schema
    {
      "type" => "object",
      "properties" => {
        "id" => { "type" => "string" },
        "rounds" => { "type" => ["array", "null"], "items" => Round.wcif_json_schema },
        "competitorLimit" => { "type" => ["integer", "null"] },
        "qualification" => Qualification.wcif_json_schema,
        "extensions" => { "type" => "array", "items" => WcifExtension.wcif_json_schema },
      },
    }
  end
end
