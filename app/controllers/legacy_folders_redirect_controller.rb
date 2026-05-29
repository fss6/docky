# frozen_string_literal: true

class LegacyFoldersRedirectController < ApplicationController
  include FoldersHelper

  before_action :authorize_folder, only: %i[show edit]

  def index
    redirect_to clients_path, status: :see_other
  end

  def new
    if current_client.present?
      redirect_to client_path(
        current_client,
        aba: "pastas",
        period: Date.current.strftime("%Y-%m")
      ), status: :see_other
    else
      redirect_to clients_path, status: :see_other
    end
  end

  def show
    redirect_to folder_destination_path(@folder), status: :see_other
  end

  def edit
    redirect_to folder_destination_path(@folder), status: :see_other
  end

  private

  def authorize_folder
    authorize Folder
    @folder = Folder.for_nav_client(current_client).find(params.expect(:id))
  end
end
