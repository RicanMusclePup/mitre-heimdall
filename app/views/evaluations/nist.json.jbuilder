def calc_status_value(status_value, curr_value, curr_total)
  if status_value
    if status_value > 0.4
      if curr_value < 0.6
        curr_total = 1
        curr_value = status_value
      else
        curr_total += 1
        curr_value += status_value
      end
      if status_value > 0.6
        curr_total += 4
        curr_value += 4 * status_value
      end
    elsif curr_value < 0.6
      curr_value = 0.4
      curr_total = 1
    end
  end
  [curr_value, curr_total]
end

def convert_severity(impact)
  if impact == 0.0
    'None'
  elsif impact == 0.3
    'Low'
  elsif impact == 0.5
    'Medium'
  elsif impact == 0.7
    'High'
  elsif impact == 1.0
    'Critical'
  end
end

def convert_status_symbol(symbol)
  case symbol
  when :not_applicable then 0.2
  when :not_reviewed then 0.4
  when :passed then 0.6
  when :failed then 0.8
  else
    0.0
  end
end

all_controls = {}
total_impact = 0
total_children = 0
json.name @name
nist_status_symbol = :not_reviewed
json.children @families do |family|
  next if family['name'] == 'UM' && @control_hash['UM-1'].nil?

  cf_total_impact = 0.0
  cf_total_children = 0
  json.name family['name']
  json.desc family['desc']
  fam_status_symbol = :not_reviewed

  json.children family['children'] do |control|
    control_total_impact = 0.0
    control_total_children = 0
    json.name control['name']
    sub_fam_status_symbol = :not_reviewed
    if @control_hash[control['name']]
      child_hsh = {}
      status_symbol = :not_reviewed
      # json.children @control_hash[control['name']].each do |child|
      @control_hash[control['name']].each do |child|
        childf = child[:children].first
        # Rails.logger.debug "children: #{child[:children].inspect}"
        # Rails.logger.debug "childf: #{childf.inspect}"
        # Rails.logger.debug "#{control['name']} keys: #{child_hsh.keys} includes #{childf[:status_symbol]}? #{child_hsh.key?(childf[:status_symbol])}"
        unless child_hsh.key?(childf[:status_symbol])
          child_hsh[childf[:status_symbol]] = []
        end
        child_hsh[childf[:status_symbol]] << childf[:name]
        all_controls[childf[:id]] = childf
        unless status_symbol == :failed
          if childf[:status_symbol] == :failed
            status_symbol = :failed
          elsif childf[:status_symbol] == :passed
            status_symbol = :passed
          end
        end
      end
      # Rails.logger.debug "#{control['name']} status_symbol: #{status_symbol}"
      json.children child_hsh.each do |key, value|
        # Rails.logger.debug "Key #{key} values: #{value}"
        uniques = {}
        value.uniq.each do |v|
          uniques[v] = 0
        end
        # iterate over the array, counting duplicate entries
        value.each do |v|
          uniques[v] += 1
        end
        # Rails.logger.debug "Key #{key} uniques #{uniques}"
        json.name key
        json.status_symbol key
        json.status_value convert_status_symbol(key)
        json.desc value.size
        # json.value 1
        if uniques.keys.size > 5
          json.children uniques.keys.each_slice(5) do |slice_keys|
            json.name "#{slice_keys.first}...#{slice_keys.last}"
            json.status_symbol key
            json.status_value convert_status_symbol(key)
            json.children slice_keys.each do |slice_key|
              json.name slice_key
              json.desc uniques[slice_key]
              json.status_symbol key
              json.status_value convert_status_symbol(key)
              json.value 1
            end
          end
        else
          json.children uniques.each do |slice_key, slice_count|
            json.name slice_key.to_s
            json.desc slice_count
            json.status_symbol key
            json.status_value convert_status_symbol(key)
            json.value 1
          end
        end
      end
      json.status_symbol status_symbol
      json.status_value convert_status_symbol(status_symbol)
      json.what_level_is_this 3
      # Rails.logger.debug "#{control['name']} status_symbol: #{status_symbol}, status_value: #{convert_status_symbol(status_symbol)}"
      unless sub_fam_status_symbol == :failed
        if status_symbol == :failed
          sub_fam_status_symbol = :failed
        elsif status_symbol == :passed
          sub_fam_status_symbol = :passed
        end
      end
    else
      json.value 1
      json.status_symbol :not_reviewed
      json.status_value convert_status_symbol(:not_reviewed)
      # Rails.logger.debug "#{control['name']} status_symbol: :not_reviewed, status_value: #{convert_status_symbol(:not_reviewed)}"
    end
    # Rails.logger.debug "#{family['name']} status_symbol: #{sub_fam_status_symbol}"
    # json.status_value control_total_impact == 0.0 ? 0.0 : control_total_impact/control_total_children
    json.status_symbol sub_fam_status_symbol
    json.status_value convert_status_symbol(sub_fam_status_symbol)
    json.what_level_is_this 2
    cf_total_impact += control_total_impact
    cf_total_children += control_total_children
    unless fam_status_symbol == :failed
      if sub_fam_status_symbol == :failed
        fam_status_symbol = :failed
      elsif sub_fam_status_symbol == :passed
        fam_status_symbol = :passed
      end
    end
    # Rails.logger.debug "#{family['name']} status_symbol: #{fam_status_symbol}, status_value: #{convert_status_symbol(fam_status_symbol)}"
  end
  json.status_symbol fam_status_symbol
  json.status_value convert_status_symbol(fam_status_symbol)
  json.what_level_is_this 1
  # json.status_value cf_total_impact == 0.0 ? 0.0 : cf_total_impact/cf_total_children
  total_impact += cf_total_impact
  total_children += cf_total_children
  unless nist_status_symbol == :failed
    if fam_status_symbol == :failed
      nist_status_symbol = :failed
    elsif fam_status_symbol == :passed
      nist_status_symbol = :passed
    end
  end
end
# json.status_value total_impact == 0.0 ? 0.0 : total_impact/total_children
json.status_symbol nist_status_symbol
json.status_value convert_status_symbol(nist_status_symbol)
json.controls all_controls.each do |key, ctl|
  json.id key
  json.family h(ctl[:family])
  json.profile_id ctl[:profile_id]
  json.profile_name h(ctl[:profile_name])
  json.name h(ctl[:name])
  json.title h(ctl[:title])
  json.description h(ctl[:description])
  json.nist ctl[:nist]
  json.status_symbol ctl[:status_symbol]
  json.status_symbol_title ctl[:status_symbol].to_s.titleize
  json.status_value ctl[:status_value]
  json.severity ctl[:severity]
  json.severity_cap convert_severity(ctl[:severity])
  json.check h(ctl[:check])
  json.fix h(ctl[:fix])
  json.result_message h(ctl[:result_message])
  json.code h(ctl[:code])
  json.start_time ctl[:start_time]
  json.run_time ctl[:run_time]
  json.impact ctl[:impact]
end
