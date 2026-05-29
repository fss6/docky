# frozen_string_literal: true

require "test_helper"

class PublicFolderUploadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @client = clients(:alpha)
    @user = users(:owner)
    @period = Date.new(2026, 5, 1)
    @period_label = "Maio/2026"

    ActsAsTenant.with_tenant(@account) do
      @period_record = Periods::OpenForClient.call(client: @client, period: @period, account: @account)
      @invite = Clients::CreateUploadInvite.call(
        client: @client,
        period: @period,
        user: @user,
        account: @account
      )
      CompetencyChecklistItem.create!(
        competency_checklist: @period_record,
        name_snapshot: "NF-e do mês",
        state: :pending
      )
      CompetencyChecklistItem.create!(
        competency_checklist: @period_record,
        name_snapshot: "Extrato bancário Itaú",
        state: :pending
      )
    end
  end

  test "show renders portal upload UI with banner and pending documents" do
    get public_folder_upload_url(token: @invite.token)

    assert_response :success
    assert_match @account.name, response.body
    assert_match "Enviando para", response.body
    assert_match @period_label, response.body
    assert_match "Envie seus documentos", response.body
    assert_match "Arraste arquivos aqui", response.body
    assert_match "Selecionar do computador", response.body
    assert_match "Documentos pendentes para #{@period_label}", response.body
    assert_match "NF-e do mês", response.body
    assert_match "Extrato bancário Itaú", response.body
    assert_match "Conexão segura", response.body
    assert_match "text-emerald-500", response.body
    assert_no_match "portal-upload-banner", response.body
    assert_no_match "competência", response.body.downcase
  end

  test "show renders unavailable when period does not exist" do
    ActsAsTenant.with_tenant(@account) do
      @period_record.destroy!
    end

    get public_folder_upload_url(token: @invite.token)

    assert_response :success
    assert_match "Envio indisponível no momento", response.body
    assert_match "períodos abertos", response.body
    assert_match @account.name, response.body
    assert_match 'alt="Dokivo"', response.body
    assert_no_match "competência", response.body.downcase
  end

  test "show renders unavailable when period is closed" do
    ActsAsTenant.with_tenant(@account) do
      Periods::Close.call(period: @period_record, user: @user)
    end

    get public_folder_upload_url(token: @invite.token)

    assert_response :success
    assert_match "Envio indisponível no momento", response.body
    assert_match @period_label, response.body
    assert_match "não está recebendo documentos", response.body
    assert_match @account.name, response.body
    assert_match 'alt="Dokivo"', response.body
    assert_no_match "competência", response.body.downcase
  end

  test "create uploads file and redirects back to portal" do
    file = fixture_file_upload("minimal.pdf", "application/pdf")

    assert_difference -> { Document.count }, 1 do
      post public_folder_upload_url(token: @invite.token), params: { document: { file: file } }
    end

    assert_redirected_to public_folder_upload_path(token: @invite.token)
    follow_redirect!

    assert_response :success
    assert_match "Enviando para", response.body
    assert_match @period_label, response.body
  end

  test "create rejects unsupported file type" do
    file = fixture_file_upload("sample.txt", "text/plain")

    assert_no_difference -> { Document.count } do
      post public_folder_upload_url(token: @invite.token), params: { document: { file: file } }
    end

    assert_response :unprocessable_entity
    assert_match "Formato não aceito", response.body
  end

  test "onboarding extra upload enqueues OCR for new file content" do
    client = create_onboarding_client
    invite = ActsAsTenant.with_tenant(@account) do
      Clients::CreateOnboardingUploadInvite.call(client: client, user: @user, account: @account)
    end
    file = fixture_file_upload("minimal.pdf", "application/pdf")

    assert_difference -> { Document.count }, 1 do
      assert_enqueued_jobs 1, only: DocumentOcrJob do
        post public_onboarding_extra_upload_path(token: invite.token), params: { document: { file: file } }
      end
    end

    assert_redirected_to public_onboarding_upload_path(token: invite.token)
    document = Document.order(:created_at).last
    assert_equal "onboarding_extra", document.metadata["upload_source"]
    assert document.content_sha256.present?
    assert_equal "pending", document.status
  end
end
