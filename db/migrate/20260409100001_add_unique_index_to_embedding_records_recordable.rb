class AddUniqueIndexToEmbeddingRecordsRecordable < ActiveRecord::Migration[8.0]
  def change
    # Índice único parcial: somente para WikiPage (1 embedding por página).
    # Documents continuam tendo múltiplos registros (1 por chunk).
    add_index :embedding_records, [:recordable_type, :recordable_id],
              unique: true,
              where: "recordable_type = 'WikiPage'",
              name: "index_embedding_records_on_wiki_page_unique"
  end
end
