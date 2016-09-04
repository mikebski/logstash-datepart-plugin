# coding: utf-8
# Copyright (c) 2014–2015 Mike Baranski <http://www.mikeski.net>

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#    http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# This filter will add date parts to your record based on
# the timestamp field.
# 
class LogStash::Filters::DateParts < LogStash::Filters::Base
  # Setting the config_name here is required. This is how you
  # configure this filter from your Logstash config.
  #
  # filter {
  #   dateparts {
  #     
  #   }
  # }
  #
  config_name "dateparts"
  config :fields, :validate => :array, :default => ["day", "wday", "yday", "month", "year", "hour", "min", "sec"], :required => true
  config :time_field, :validate => :string, :default => "@timestamp", :required => true
  config :error_tags, :validate => :array, :default => ["_dateparts_error"], :required => true
  
  public
  def register
    logger.debug? and logger.debug("DateParts filter registered")
  end

  def plugin_error(message, event)
    logger.error("DatePart filter error: " + message)
    LogStash::Util::Decorators.add_tags(@error_tags, event, "filters/#{self.class.name}")
  end

  def get_time_from_field(f)
    if f.class == Time
      return f
    elsif f.respond_to?("time")
      logger.info("Class is #{f.class}")
      return f.time()
    else
      return nil
    end
  end
  
  public
  def filter(event)
    if @fields.respond_to?("each") and @fields.respond_to?("join")
      logger.debug? and logger.debug("DateParts plugin filtering #{@time_field} time_field and adding fields: " + @fields.join(", "))
      t = get_time_from_field(event.get(@time_field))
      if t == nil
        plugin_error("Invalid time field #{@time_field}; Time field must be an instance of Time or provide a time method that returns one", event)
        return
      end
      @fields.each do |field|
        begin
          event.set(field, t.send(field))
        rescue
          plugin_error("No such method: #{field}\n", event)
        end
      end
    else
      plugin_error("DateParts plugin fields invalid, should be an array of function names")
      return
    end
      
    filter_matched(event)
  end # def filter
  
end # class LogStash::Filters::DateParts
