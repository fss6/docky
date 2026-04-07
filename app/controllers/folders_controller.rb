class FoldersController < ApplicationController
  before_action :set_folder, only: %i[show edit update destroy]
  before_action :authorize_policy

  # GET /folders or /folders.json
  def index
    @folders = Folder.includes(:account)
                     .left_joins(:documents)
                     .select("folders.*, COUNT(documents.id) AS documents_count")
                     .group("folders.id")
                     .order(:name)
    @selected_folder = @folders.find { |folder| folder.id == params[:folder_id].to_i } || @folders.first
    @documents = if @selected_folder
      @selected_folder.documents.includes(:user, :folder).with_attached_file.order(created_at: :desc)
    else
      Document.none
    end
  end

  # GET /folders/1 or /folders/1.json
  def show
    @recent_documents = @folder.documents.with_attached_file.includes(:user).order(created_at: :desc).limit(10)
  end

  # GET /folders/new
  def new
    @folder = Folder.new
  end

  # GET /folders/1/edit
  def edit
  end

  # POST /folders or /folders.json
  def create
    @folder = Folder.new(folder_params)

    respond_to do |format|
      if @folder.save
        format.html { redirect_to @folder, notice: "Pasta criada com sucesso." }
        format.json { render :show, status: :created, location: @folder }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @folder.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /folders/1 or /folders/1.json
  def update
    respond_to do |format|
      if @folder.update(folder_params)
        format.html { redirect_to @folder, notice: "Pasta atualizada com sucesso.", status: :see_other }
        format.json { render :show, status: :ok, location: @folder }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @folder.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /folders/1 or /folders.json
  def destroy
    @folder.destroy!

    respond_to do |format|
      format.html { redirect_to folders_path, notice: "Pasta excluída com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def authorize_policy
      authorize Folder
    end
    
    # Use callbacks to share common setup or constraints between actions.
    def set_folder
      @folder = Folder.includes(:account).find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def folder_params
      params.expect(folder: [:name])
    end
end
