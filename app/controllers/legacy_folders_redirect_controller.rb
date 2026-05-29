# frozen_string_literal: true

class LegacyFoldersRedirectController < ApplicationController
  include FoldersHelper

  before_action :authorize_folder, only: %i[show edit]

  def index
    authorize Folder
    redirect_to clients_path, status: :see_other
  end

  def new
    authorize Folder
    redirect_to clients_path, status: :see_other
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
    @folder = Folder.find(params.expect(:id))
  end
end
