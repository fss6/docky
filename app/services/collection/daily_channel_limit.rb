# frozen_string_literal: true

module Collection
  class DailyChannelLimit
    def self.reached?(client:, channel:, at: Time.current)
      new(client: client, channel: channel, at: at).reached?
    end

    def initialize(client:, channel:, at:)
      @client = client
      @channel = channel.to_sym
      @at = at
    end

    def reached?
      return false if @channel == :internal

      today_range = @at.in_time_zone(Time.zone).to_date.all_day
      count = CollectionDispatch.status_sent
        .where(client: @client, channel: @channel, sent_at: today_range)
        .count
      count >= CollectionSetting::MAX_MESSAGES_PER_CLIENT_PER_CHANNEL
    end
  end
end
