puts "Event Manager Initialized!"
require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'


contents = CSV.open('event_attendees.csv',headers: true, header_converters: :symbol)

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,'0')[0..4]
end

def clean_phone(phone_number)
  clean_num = phone_number.to_s.tr('^0-9','')
  if clean_num.length < 10 or clean_num.length > 11
    return 'Invalid Number'
  elsif clean_num.length == 11
    return clean_num[0] == 1 ? clean_num[1..9] : 'Invalid First Number'
  end
  clean_num
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )
    legislators = legislators.officials
    legislator_names = legislators.map(&:name)
    legislator_names.join(", ")
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  homephone =  clean_phone(row[:homephone])
  puts homephone

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_lettter = erb_template.result(binding)

  save_thank_you_letter(id, form_lettter)
end
