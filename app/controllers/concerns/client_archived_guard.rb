# frozen_string_literal: true

module ClientArchivedGuard
  extend ActiveSupport::Concern

  private

  def redirect_if_client_archived!
    return unless @client&.archived?

    redirect_to client_path(@client, archived_redirect_params),
                alert: I18n.t("clients.archived.mutation_blocked"),
                status: :see_other
  end

  def archived_redirect_params
    params = {}
    params[:period] = request.query_parameters["period"] if request.query_parameters["period"].present?
    params[:aba] = request.query_parameters["aba"] if request.query_parameters["aba"].present?
    params
  end
end
