# frozen_string_literal: true

module Permissions
  module Catalog
    MEMBER_ROLE = "member"

    DEFINITIONS = {
      "clients.read" => { default_member: true, group: :clients },
      "clients.write" => { default_member: true, group: :clients },
      "documents.read" => { default_member: true, group: :documents },
      "documents.write" => { default_member: true, group: :documents },
      "documents.destroy" => { default_member: true, group: :documents },
      "institutions.read" => { default_member: true, group: :institutions },
      "institutions.manage" => { default_member: false, group: :institutions },
      "groups.read" => { default_member: true, group: :groups },
      "groups.manage" => { default_member: false, group: :groups },
      "users.manage" => { default_member: false, group: :users },
      "settings.read" => { default_member: true, group: :settings },
      "settings.manage" => { default_member: false, group: :settings },
      "conversations.use" => { default_member: true, group: :conversations },
      "wiki.read" => { default_member: true, group: :wiki },
      "audit.read" => { default_member: false, group: :audit }
    }.freeze

    KEYS = DEFINITIONS.keys.freeze

    GROUPS = {
      clients: "Clientes",
      documents: "Documentos",
      institutions: "Instituições",
      groups: "Grupos",
      users: "Usuários",
      settings: "Configurações",
      conversations: "Assistente IA",
      wiki: "Wiki",
      audit: "Auditoria"
    }.freeze

    module_function

    def keys
      KEYS
    end

    def valid_key?(key)
      normalized = normalize_key(key)
      KEYS.include?(normalized)
    end

    def normalize_key(key)
      key.to_s.tr("_", ".")
    end

    def default_for_member(key)
      definition = DEFINITIONS[normalize_key(key)]
      return false unless definition

      definition[:default_member]
    end

    def platform_capability?(_key)
      false
    end

    def grouped_keys
      GROUPS.keys.index_with do |group|
        DEFINITIONS.select { |_key, meta| meta[:group] == group }.keys
      end
    end
  end
end
