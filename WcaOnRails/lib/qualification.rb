# frozen_string_literal: true

class Qualification
  include ActiveModel::Validations

  attr_accessor :when_date
  validates :when_date, presence: true

  def ==(other)
    other.class == self.class && other.to_wcif == self.to_wcif
  end

  def hash
    self.to_wcif.hash
  end

  def self.wcif_type_to_class
    @@wcif_type_to_class ||= Qualification.subclasses.map { |cls| [cls.wcif_type, cls] }.to_h
  end

  def self.load(json)
    if json.nil? || json.is_a?(self)
      json
    else
      json_obj = json.is_a?(Hash) ? json : JSON.parse(json)
      wcif_type = json_obj['type']
      out = self.wcif_type_to_class[wcif_type].new(json_obj)
      begin
        out.when_date = Date.iso8601(json_obj['whenDate'])
      rescue ArgumentError => e
      end
      out
    end
  end

  def self.dump(qualification)
    qualification ? JSON.dump(qualification.to_wcif) : nil
  end

  def self.wcif_json_schema
    {
      "type" => ["object", "null"],
      "properties" => {
        "whenDate" => { "type" => "string" },
        "type" => { "type" => "string", "enum" => Qualification.subclasses.map(&:wcif_type) },
        "ranking" => { "type" => "integer" },
        "attemptResult" => { "type" => "integer" },
      },
    }
  end
end

class RankingQualification < Qualification
  attr_accessor :ranking
  validates :ranking, numericality: { only_integer: true, greater_than: 0 }

  def self.wcif_type
    "ranking"
  end

  def to_wcif
    {
      "type" => self.class.wcif_type,
      "whenDate" => @when_date&.strftime("%Y-%m-%d"),
      "ranking" => ranking,
    }
  end

  def initialize(json_obj)
    self.ranking = json_obj['ranking']
  end

  def to_s(event)
    I18n.t("qualification.ranking", ranking: ranking)
  end
end

class SingleQualification < Qualification
  attr_accessor :attemptResult
  validates :attemptResult, numericality: { only_integer: true, greater_than: 0 }

  def self.wcif_type
    "single"
  end

  def to_wcif
    {
      "type" => self.class.wcif_type,
      "whenDate" => @when_date&.strftime("%Y-%m-%d"),
      "attemptResult" => attemptResult,
    }
  end

  def initialize(json_obj)
    self.attemptResult = json_obj['attemptResult']
  end

  def to_s(event)
    if event.event.timed_event?
      I18n.t("qualification.single.time", time: SolveTime.centiseconds_to_clock_format(attemptResult))
    elsif event.event.fewest_moves?
      I18n.t("qualification.single.moves", moves: attemptResult)
    elsif event.event.multiple_blindfolded?
      I18n.t("qualification.single.points", points: SolveTime.multibld_attempt_to_points(attemptResult))
    end
  end
end

class AverageQualification < Qualification
  attr_accessor :attemptResult
  validates :attemptResult, numericality: { only_integer: true, greater_than: 0 }

  def self.wcif_type
    "average"
  end

  def to_wcif
    {
      "type" => self.class.wcif_type,
      "whenDate" => @when_date&.strftime("%Y-%m-%d"),
      "attemptResult" => attemptResult,
    }
  end

  def initialize(json_obj)
    self.attemptResult = json_obj['attemptResult']
  end

  def to_s(event, short: false)
    if event.event.timed_event?
      I18n.t("qualification.average.time", time: SolveTime.centiseconds_to_clock_format(attemptResult))
    elsif event.event.fewest_moves?
      I18n.t("qualification.average.moves", moves: attemptResult)
    elsif event.event.multiple_blindfolded?
      I18n.t("qualification.average.points", points: SolveTime.multibld_attempt_to_points(attemptResult))
    end
  end
end
