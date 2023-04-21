class ModelNamesController < ApplicationController
  before_action :set_model_name, only: %i[ show edit update destroy ]

  # GET /model_names or /model_names.json
  def index
    @model_names = ModelName.all
  end

  # GET /model_names/1 or /model_names/1.json
  def show
  end

  # GET /model_names/new
  def new
    @model_name = ModelName.new
  end

  # GET /model_names/1/edit
  def edit
  end

  # POST /model_names or /model_names.json
  def create
    @model_name = ModelName.new(model_name_params)

    respond_to do |format|
      if @model_name.save
        format.html { redirect_to model_name_url(@model_name), notice: "Model name was successfully created." }
        format.json { render :show, status: :created, location: @model_name }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @model_name.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /model_names/1 or /model_names/1.json
  def update
    respond_to do |format|
      if @model_name.update(model_name_params)
        format.html { redirect_to model_name_url(@model_name), notice: "Model name was successfully updated." }
        format.json { render :show, status: :ok, location: @model_name }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @model_name.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /model_names/1 or /model_names/1.json
  def destroy
    @model_name.destroy

    respond_to do |format|
      format.html { redirect_to model_names_url, notice: "Model name was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_model_name
      @model_name = ModelName.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def model_name_params
      params.fetch(:model_name, {})
    end
end
