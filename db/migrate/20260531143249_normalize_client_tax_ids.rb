# frozen_string_literal: true

class NormalizeClientTaxIds < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      UPDATE clients
      SET tax_id = regexp_replace(tax_id, '[^0-9]', '', 'g')
      WHERE tax_id IS NOT NULL AND tax_id <> ''
    SQL
  end

  def down
    # irreversible — formatting was not stored
  end
end
