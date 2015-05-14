class Event
  include HTTParty
  BASE_URI = "http://confreaks.tv/api/v1"
  base_uri "http://confreaks.tv/api/v1"
  attr_accessor :short_code, :conference_name, :conference_id, :video_count, :date

  def initialize(short_code, conference_name, conference_id, video_count, date)
    self.short_code = short_code
    self.conference_name = conference_name
    self.conference_id = conference_id
    self.video_count = video_count
    self.date = date
  end

  # Alias short_code as name; "short_code" is consistent with the api, but "name" is easier to remember
  def name
    short_code
  end

  def to_s
    %Q{\nConference: #{conference_name}\nNumber of Videos: #{video_count}}
  end

  def self.find(short_code)
    response = get("/events/#{short_code}.json")
    if response["status"] == 404
      self.new(
        "Not Found",
        "Not Found",
        "Not Found",
        "Not Found",
        "Not Found"
      )
    elsif response.success?
      self.new(
        response["short_code"],
        response["conference"]["name"],
        response["conference"]["id"],
        response["video_count"],
        fix_date(response["start_at"])
      )
    else
      # This raises the net/http response that was raised
      raise response.response
    end
  end

  def find_conference
    Conference.find(self.conference_name)
  end

  def videos
    response = HTTParty.get("#{BASE_URI}/events/#{short_code}/videos.json")
    if response.success?
      return response
    else
      # This raises the net/http response that was raised
      raise response.response
    end
  end

  # TODO: This implementation isn't really ideal. By calling the videos method you're hitting the api again.
  # Ideally you want to just hit the api once and store that information away since you know that hitting the API takes more resources (and time frankly) then just storing the names in memory which is all you really care about until you need to actually get the information for that particular video
  #
  # Probably should do something like store the list of video names as strings as soon as you create the object and then keep that array for future use
  # This seems slightly better but I'm still not sure it's ideal
  def video_list
    if self.videos == "Not Found"
      "There was no conference found by that name."
    else
      videos.map { |video| video["title"] }
    end
  end

  private

  def fix_date(date)
    # Takes arg like this: "2013-04-29T06:00:00.00Z0"
    # and returns as date object
    time = time[0..9]
    year = str[0..3]
    month = str[5..6]
    day = str[8..9]
    Date.new(year, month, day)
  end

end
