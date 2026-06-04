# frozen_string_literal: true

module Collection
  TestDispatch = Struct.new(:rendered_subject, :rendered_body, :client, keyword_init: true)
end
