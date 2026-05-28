# frozen_string_literal: true

module Clients
  class BaseController < ApplicationController
    include ClientArchivedGuard

    before_action :redirect_if_client_archived!, unless: :safe_http_method_for_archived_client?

    private

    def safe_http_method_for_archived_client?
      request.get? || request.head?
    end
  end
end
