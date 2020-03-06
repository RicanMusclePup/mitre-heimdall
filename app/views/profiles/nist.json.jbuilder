def convert_impact(impact)
  if impact == 'none'
    0.0
  elsif impact == 'low'
    0.3
  elsif impact == 'medium'
    0.5
  elsif impact == 'high'
    0.7
  elsif impact == 'critical'
    1.0
  end
end

def convert_severity(impact)
  if impact == 0.0
    'none'
  elsif impact == 0.3
    'low'
  elsif impact == 0.5
    'medium'
  elsif impact == 0.7
    'high'
  elsif impact == 1.0
    'critical'
  end
end

total_impact = 0
total_children = 0
json.name @name
json.children @families do |family|
  next if family['name'] == 'UM' && @control_hash['UM-1'].nil?

  cf_total_impact = 0.0
  cf_total_children = 0
  json.name family['name']
  json.desc family['desc']
  json.children family['children'] do |control|
    control_total_impact = 0.0
    control_total_children = 0
    json.name control['name']
    json.value 1
    if @control_hash[control['name']]
      json.children @control_hash[control['name']].each do |child|
        json.name child[:name]
        json.severity convert_severity(child[:severity])
        json.impact child[:impact]
        json.value 1
        Rails.logger.debug "child[:impact]: #{child[:impact]}"
        if child[:impact]
          control_total_children += 1
          control_total_impact += child[:impact]
          Rails.logger.debug "control_total_impact += #{child[:impact]}: #{control_total_impact}"
        end
      end
    end
    json.impact control_total_impact == 0.0 ? 0.0 : control_total_impact/control_total_children
    cf_total_impact += control_total_impact
    cf_total_children += control_total_children
  end
  json.impact cf_total_impact == 0.0 ? 0.0 : cf_total_impact/cf_total_children
  total_impact += cf_total_impact
  total_children += cf_total_children
end
json.impact total_impact == 0.0 ? 0.0 : total_impact/total_children
