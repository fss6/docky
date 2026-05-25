# frozen_string_literal: true

class ClientDocumentsChannel < ApplicationCable::Channel
  def subscribed
    client = current_user.account.clients.find_by(id: params[:client_id])
    reject unless client

    stream_from "client_#{client.id}_documents"
  end
end
