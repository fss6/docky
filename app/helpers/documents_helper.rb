module DocumentsHelper
  DOCUMENT_HEURISTIC_CATEGORIES = {
    "nfe" => "NF-e",
    "extrato" => "Extratos",
    "comprovante" => "Comprovantes",
    "outros" => "Outros"
  }.freeze

  def document_status_options
    [
      ["Pendente", "pending"],
      ["Em processamento", "processing"],
      ["Processado", "processed"],
      ["Falhou", "failed"]
    ]
  end

  def document_status_label(status)
    {
      "pending" => "Pendente",
      "processing" => "Em processamento",
      "processed" => "Processado",
      "failed" => "Falhou"
    }[status.to_s] || status.to_s
  end

  def document_status_badge_classes(status)
    case status.to_s
    when "processed"
      "bg-teal-50 text-teal-800 ring-1 ring-inset ring-teal-600/20"
    when "processing", "pending"
      "bg-amber-50 text-amber-900 ring-1 ring-inset ring-amber-600/20"
    when "failed"
      "bg-red-50 text-red-800 ring-1 ring-inset ring-red-600/20"
    else
      "bg-zinc-100 text-zinc-700"
    end
  end

  def document_file_label(document)
    return "—" unless document.file.attached?

    document.file.filename.to_s
  end

  def document_heuristic_category(document)
    return "outros" unless document.file.attached?

    filename = document.file.filename.to_s.downcase
    content_type = document.file.content_type.to_s.downcase

    if filename.end_with?(".xml") || content_type.include?("xml")
      "nfe"
    elsif filename.end_with?(".pdf") || content_type == "application/pdf"
      "extrato"
    elsif content_type.start_with?("image/")
      "comprovante"
    else
      "outros"
    end
  end

  def document_heuristic_category_label(key)
    DOCUMENT_HEURISTIC_CATEGORIES[key] || key.to_s.titleize
  end

  def document_card_subtitle(document, linked_item)
    source = document.upload_source_label
    if linked_item
      "Recebido via #{source} · vinculado a '#{linked_item.name_snapshot}'"
    else
      "Recebido via #{source} · não vinculado"
    end
  end

  def document_icon_classes(document)
    cat = document_heuristic_category(document)
    case cat
    when "nfe" then "text-sky-600"
    when "extrato" then "text-red-600"
    when "comprovante" then "text-amber-600"
    else "text-zinc-500"
    end
  end
end
