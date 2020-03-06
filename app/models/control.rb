require 'ripper'

class Control < ApplicationRecord
  #serialize :refs_array
  #store :waiver_data_hash, accessors: [:justification, :run, :skipped_due_to_waiver, :message], coder: JSON
  belongs_to :profile, inverse_of: :controls
  has_many :tags, as: :tagger, dependent: :destroy
  has_many :descriptions, dependent: :destroy
  has_many :results, dependent: :destroy
  has_many :refs, dependent: :destroy
  has_one :source_location, dependent: :destroy
  has_many :waiver_data, dependent: :destroy
  accepts_nested_attributes_for :tags
  accepts_nested_attributes_for :descriptions
  accepts_nested_attributes_for :source_location
  accepts_nested_attributes_for :results
  accepts_nested_attributes_for :refs
  accepts_nested_attributes_for :waiver_data

  def to_jbuilder(skip_results=false)
    Jbuilder.new do |json|
      json.extract! self, :title, :desc, :impact, :refs, :waiver_data
      json.tags do
        tags.each do |tag|
          json.set!(tag.content['name'], tag.content['value'])
        end
      end
      json.extract! self, :code
      if source_location.present?
        json.source_location do
          json.ref source_location.ref
          json.line source_location.line
        end
      end
      json.id control_id
      unless skip_results
        if results.present?
          json.results(results.collect { |result| result.to_jbuilder.attributes! })
        end
      end
    end
  end

  def as_json
    to_jbuilder.attributes!
  end

  def to_json(*_args)
    to_jbuilder.target!
  end

  def start_time
    results.map(&:start_time).min
  end

  def run_time
    results.map(&:run_time).inject(0, :+).round(6)
  end

  def eval_waiver_data(eval_id)
    waiver_data.where(evaluation_id: eval_id).first
  end

  def tag(name, good = false)
    tag_obj = tags.select { |tag| tag.content['name'] == name }.first
    if tag_obj
      if good
        tag_obj.good_values
      else
        tag_obj.content['value']
      end
    else
      desc_obj = descriptions.select { |desc| desc.label == name }.first
      if desc_obj
        desc_obj.data
      else
        ''
      end
    end
  end

  def severity
    impact
  end

  def parse_nist_tag(nist_tag)
    if (m_fields = nist_tag.match(/([A-Z]{2})\-(\d+)((\s*([a-z])|\.([a-z])){1}((\.|\s+)(\d+))?)?\s*(\(\d+\))?((\s*([a-z])|\.([a-z])|\s*\(([a-z])\)){1}((\.|\s+)(\d+))?)?/))
      # <MatchData "AC-15 a 3(2) b 2" 1:"AC" 2:"15" 3:" a 3" 4:" a" 5:"a" 6:nil 7:" 3" 8:" " 9:"3" 10:"(2)" 11:" b 2" 12:" b" 13:"b" 14:nil 15:nil 16:" 2" 17:" " 18:"2">
      value = "#{m_fields[1]}-#{m_fields[2]}"
      value += ".#{m_fields[5] || m_fields[6]}" if m_fields[4].present?
      value += ".#{m_fields[9]}" if m_fields[9].present?
      value += m_fields[10] if m_fields[10].present?
      value += ".#{m_fields[13] || m_fields[14] || m_fields[15]}" if m_fields[12].present?
      value += ".#{m_fields[18]}" if m_fields[18].present?
      value
    else
      nist_tag
    end
  end

  def nist_tags
    values = []
    nist_tags = tag('nist')
    if nist_tags != ''
      Rails.logger.debug "nist_tags: #{nist_tags}"
      nist_tags.map(&:strip).each do |nist_tag|
        values << parse_nist_tag(nist_tag)
      end
    end
    values
  end

  def short_title
    title.nil? ? '' : "#{title[0..50]}..."
  end

  def parse_update(params)
    assign_attributes(params)
    if (new_control = Control.parse(params[:code]))
      self.title = new_control.title
      self.desc = new_control.desc
      self.impact = new_control.impact
      self.tags = new_control.tags
    end
  end

  def self.transform(controls, evaluation_id=nil)
    controls.try(:each) do |control|
      tags = control.delete('tags')
      new_tags = []
      tags.each do |key, value|
        new_tags << { 'content': { "name": key.to_s, "value": value } }
      end
      Rails.logger.debug "NEW TAGS: #{new_tags.inspect}"
      control[:tags_attributes] = new_tags
      control['impact'] = control['impact']
      source_location = control.delete('source_location')
      if source_location.present?
        control[:source_location_attributes] = source_location
      end
      waiver_data = control.delete('waiver_data')
      results = control.delete('results')
      if evaluation_id.present?
        if waiver_data.present?
          waiver_data[:evaluation_id] = evaluation_id
          control[:waiver_data_attributes] = []
          control[:waiver_data_attributes] << waiver_data
        end
        if results.present?
          results.each do |result|
            result[:evaluation_id] = evaluation_id
          end
        end
        control[:results_attributes] = results || []
      end
      descriptions = control.delete('descriptions')
      control[:descriptions_attributes] = descriptions || []
      refs = control.delete('refs')
      control[:refs_attributes] = refs || []
    end
    controls
  end

  def self.parse_impact(value)
    if ['none', 'low', 'medium', 'high', 'critical'].include?(value)
      impact = value
    else
      if value.nil?
        'none'
      else
        if [Float, Integer].include?(value.class)
          impact = value
        elsif value.numeric?
          impact = value.to_f
        end
        if impact < 0.1 then 'none'
        elsif impact < 0.4 then 'low'
        elsif impact < 0.7 then 'medium'
        elsif impact < 0.9 then 'high'
        elsif impact >= 0.9 then 'critical'
        end
      end
    end
  end
end
