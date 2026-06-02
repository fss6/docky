# frozen_string_literal: true

module Collection
  class ChannelEligibility
    def self.skip_reason(channel:, client:, account:, step:, settings:)
      new(channel: channel, client: client, account: account, step: step, settings: settings).skip_reason
    end

    def self.deliverable?(**kwargs)
      skip_reason(**kwargs).nil?
    end

    def self.any_deliverable?(channels:, client:, account:, step:, settings:)
      channels.any? do |channel|
        deliverable?(channel: channel, client: client, account: account, step: step, settings: settings)
      end
    end

    def initialize(channel:, client:, account:, step:, settings:)
      @channel = channel.to_sym
      @client = client
      @account = account
      @step = step
      @settings = settings
    end

    def skip_reason
      pref = ClientCollectionPreference.ensure_for!(@client)

      return "email_opt_out" if @channel == :email && pref.email_opted_out?
      return "whatsapp_opt_out" if @channel == :whatsapp && pref.whatsapp_opted_out?
      return "email_not_configured" if @channel == :email && !ActionMailerDelivery.enabled?
      return "whatsapp_not_configured" if @channel == :whatsapp && !Whatsapp::PlatformConfig.configured?
      return "no_email" if @channel == :email && @client.email.blank?
      return "no_phone" if @channel == :whatsapp && @client.phone.blank?
      return "no_contact_email" if @channel == :internal && @account.contact_email.blank?
      return "daily_limit" if daily_limit_reached?
      return "missing_whatsapp_template" if @channel == :whatsapp && @step.whatsapp_template_name.blank?

      nil
    end

    private

    def daily_limit_reached?
      today_range = Time.zone.today.all_day
      count = CollectionDispatch.status_sent.where(client: @client, sent_at: today_range).count
      count >= @settings.max_messages_per_client_per_day
    end
  end
end
