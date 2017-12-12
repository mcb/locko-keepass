#!/usr/bin/env ruby

require 'json'
require 'date'
require 'nokogiri'
require 'securerandom'

input_dir = ARGV[0]
data      = []
timestamp = DateTime.now.strftime("%Y-%m-%dT%H:%M:%SZ")

Struct.new("PwEntry", :title, :username, :password, :url, :notes, :group, :uuid)

Dir.glob("#{input_dir}/*.item") do |category_item|
  cat_item       = JSON.parse(File.read(category_item))
  category_title = cat_item["title"].to_s
  category_type  = cat_item["type"].to_i

  category_dir = File.basename(category_item, ".item")
  Dir.glob("#{input_dir}/#{category_dir}/*.item") do |locko_item|
    file = JSON.parse(File.read(locko_item))

    title       = file["title"].to_s
    username    = file["data"]["fields"]["username"].to_s
    password    = file["data"]["fields"]["password"].to_s
    url         = file["data"]["fields"]["serverAddress"].to_s
    uuid        = file["uuid"]
    # notes       = file["data"]["fields"]["note"]

    if category_type == 8 || category_type == 5
        notes = "Had an attachment in Locko, please find this in #{input_dir}/#{category_dir}/#{File.basename(locko_item, ".item")}/"
    else 
        notes = file["data"]["fields"]["note"].to_s
    end
    data << Struct::PwEntry.new(title, username, password, url, notes, category_title, uuid)
  end
end

builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
  xml.KeePassFile {
    xml.Meta
    xml.Root {
      xml.Group {
        xml.UUID SecureRandom.base64(nil)
        xml.Name "General"
        data.each do |p|
          xml.Entry {
            xml.UUID SecureRandom.base64(nil)
            p.each_pair do |name, value|
            xml.String {
              xml.Key   name.capitalize
              xml.Value value
            }
            end
          }
        end
      }
    }
  }
end

File.write("#{__dir__}/keepass.xml", builder.to_xml)

puts "Successfully exported xml. Please find it at #{__dir__}/keepass.xml"

