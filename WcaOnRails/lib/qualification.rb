# frozen_string_literal: true

class Qualification
  include ActiveModel::Validations

  attr_accessor :when_time
  validates :when_time, presence: true

  def ==(other)
    other.class == self.class && other.to_wcif == self.to_wcif
  end

  def hash
    self.to_wcif.hash
  end

  def met?(user, event_id)
    user.person && qualifying_results(user.person.results.in_event(event_id).before(self.when_time)).any?
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
        out.when_time = Date.iso8601(json_obj['when'])
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
        "when" => { "type" => "string" },
        "type" => { "type" => "string", "enum" => Qualification.subclasses.map(&:wcif_type) },
        "ranking" => { "type" => "integer" },
        "single" => { "type" => "integer" },
        "average" => { "type" => "integer" },
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

  def qualifying_results(r)
    r.succeeded
  end

  def to_wcif
    {
      "type" => self.class.wcif_type,
      "when" => @when_time&.strftime("%Y-%m-%d"),
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
  attr_accessor :single
  validates :single, numericality: { only_integer: true, greater_than: 0 }

  def self.wcif_type
    "single"
  end

  def qualifying_results(r)
    r.single_better_than(single)
  end

  def to_wcif
    {
      "type" => self.class.wcif_type,
      "when" => @when_time&.strftime("%Y-%m-%d"),
      "single" => single,
    }
  end

  def initialize(json_obj)
    self.single = json_obj['single']
  end

  def to_s(event)
    if event.event.timed_event?
      I18n.t("qualification.single.time", time: SolveTime.centiseconds_to_clock_format(single))
    elsif event.event.fewest_moves?
      I18n.t("qualification.single.moves", moves: single)
    elsif event.event.multiple_blindfolded?
      I18n.t("qualification.single.points", points: SolveTime.multibld_attempt_to_points(single))
    end
  end
end

class AverageQualification < Qualification
  attr_accessor :average
  validates :average, numericality: { only_integer: true, greater_than: 0 }

  def self.wcif_type
    "average"
  end

  def qualifying_results(r)
    r.average_better_than(average)
  end

  def to_wcif
    {
      "type" => self.class.wcif_type,
      "when" => @when_time&.strftime("%Y-%m-%d"),
      "average" => average,
    }
  end

  def initialize(json_obj)
    self.average = json_obj['average']
  end

  def to_s(event, short: false)
    if event.event.timed_event?
      I18n.t("qualification.average.time", time: SolveTime.centiseconds_to_clock_format(average))
    elsif event.event.fewest_moves?
      I18n.t("qualification.average.moves", moves: average)
    elsif event.event.multiple_blindfolded?
      I18n.t("qualification.average.points", points: SolveTime.multibld_attempt_to_points(average))
    end
  end
end
