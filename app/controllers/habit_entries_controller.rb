class HabitEntriesController < ApplicationController
  before_action :set_habit_entry, only: %i[ show edit update destroy ]

  # GET /habit_entries or /habit_entries.json
  def index
    @habit_entries = HabitEntry.all
  end

  # GET /habit_entries/1 or /habit_entries/1.json
  def show
  end

  # GET /habit_entries/new
  def new
    @habit_entry = HabitEntry.new
  end

  # GET /habit_entries/1/edit
  def edit
  end

  # POST /habit_entries or /habit_entries.json
  def create
    @habit_entry = HabitEntry.new(habit_entry_params)

    respond_to do |format|
      if @habit_entry.save
        format.html { redirect_to @habit_entry, notice: "Habit entry was successfully created." }
        format.json { render :show, status: :created, location: @habit_entry }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @habit_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /habit_entries/1 or /habit_entries/1.json
  def update
    respond_to do |format|
      if @habit_entry.update(habit_entry_params)
        format.html { redirect_to @habit_entry, notice: "Habit entry was successfully updated." }
        format.json { render :show, status: :ok, location: @habit_entry }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @habit_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /habit_entries/1 or /habit_entries/1.json
  def destroy
    @habit_entry.destroy!

    respond_to do |format|
      format.html { redirect_to habit_entries_path, status: :see_other, notice: "Habit entry was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_habit_entry
      @habit_entry = HabitEntry.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def habit_entry_params
      params.fetch(:habit_entry, {})
    end
end
