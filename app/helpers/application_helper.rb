module ApplicationHelper
  def format_datetime(datetime, zone)
    if zone
      datetime.in_time_zone(zone).strftime("%b %-d, %Y %l:%M %p %z")
    else
      datetime.strftime("%b %-d, %Y %l:%M %p %z")
    end
  end

  def site_title
    if ENV["SIMPLECMS_TITLE"] && !ENV["SIMPLECMS_TITLE"].empty?
      ENV["SIMPLECMS_TITLE"]
    else
      "SimpleCMS"
    end
  end
end
