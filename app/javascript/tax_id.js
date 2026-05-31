const MASK_CHARS = /[.\/\-\s]/g

export function normalizeTaxId(value) {
  const raw = value.toString().replace(MASK_CHARS, "").toUpperCase()
  if (!raw) return ""

  const digitsOnly = raw.replace(/\D/g, "")
  const isCpfCandidate =
    /^[\d.\-\s]+$/i.test(value.toString()) && digitsOnly.length <= 11 && !/[A-Z]/i.test(raw)

  if (isCpfCandidate) {
    return digitsOnly.slice(0, 11)
  }

  return raw.replace(/[^0-9A-Z]/g, "").slice(0, 14)
}

export function searchNormalizeTaxId(term) {
  const raw = term.toString().replace(MASK_CHARS, "").toUpperCase()
  if (!raw) return ""

  if (/^\d+$/.test(raw) && raw.length <= 11) {
    return raw.replace(/\D/g, "")
  }

  return raw.replace(/[^0-9A-Z]/g, "")
}

export function maskMode(normalized, prefer = "auto") {
  if (!normalized) return "cpf"
  if (/[A-Z]/.test(normalized)) return "cnpj"
  if (normalized.length > 11) return "cnpj"
  if (prefer === "cnpj") return "cnpj"
  if (prefer === "cpf") return "cpf"
  if (normalized.length <= 11 && /^\d+$/.test(normalized)) return "cpf"
  return "cnpj"
}

export function isCompleteTaxId(normalized) {
  return normalized.length === 11 || normalized.length === 14
}

export function formatTaxId(normalized, options = {}) {
  const prefer = options.prefer || "auto"
  if (!normalized) return ""

  if (maskMode(normalized, prefer) === "cpf") {
    return normalized
      .replace(/^(\d{3})(\d)/, "$1.$2")
      .replace(/^(\d{3})\.(\d{3})(\d)/, "$1.$2.$3")
      .replace(/^(\d{3})\.(\d{3})\.(\d{3})(\d)/, "$1.$2.$3-$4")
  }

  const body = normalized.slice(0, 14)
  let formatted = body
    .replace(/^([0-9A-Z]{2})([0-9A-Z])/, "$1.$2")
    .replace(/^([0-9A-Z]{2})\.([0-9A-Z]{3})([0-9A-Z])/, "$1.$2.$3")
    .replace(/^([0-9A-Z]{2})\.([0-9A-Z]{3})\.([0-9A-Z]{3})([0-9A-Z])/, "$1.$2.$3/$4")
    .replace(
      /^([0-9A-Z]{2})\.([0-9A-Z]{3})\.([0-9A-Z]{3})\/([0-9A-Z]{4})(\d{1,2})/,
      "$1.$2.$3/$4-$5"
    )

  return formatted
}
