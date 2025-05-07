class HabitEntriesController < ApplicationController
  before_action :set_habit_entry, only: %i[ show edit update destroy ]
  before_action :set_habit

  # GET /habit_entries or /habit_entries.json
  def index
    @habit_entries = HabitEntry.all
  end

  # GET /habit_entries/1 or /habit_entries/1.json
  def show
  end

  # GET /habit_entries/new
  def new
    @habit_entry = @habit.habit_entries.build(date: params[:date])
  end

  # GET /habit_entries/1/edit
  def edit
  end

  # POST /habit_entries or /habit_entries.json
  def create
    @habit_entry = @habit.habit_entries.build(habit_entry_params)
    if @habit_entry.save
      redirect_to @habit, notice: 'Entry was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /habit_entries/1 or /habit_entries/1.json
  def update
    respond_to do |format|
      if @habit_entry.update(habit_entry_params)
        format.html { redirect_to habit_habit_entry_path(@habit, @habit_entry), notice: "Habit entry was successfully updated." }
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
      format.html { redirect_to @habit, status: :see_other, notice: "Habit entry was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_habit_entry
      @habit_entry = HabitEntry.find(params.expect(:id))
    end

    def set_habit
      @habit = Habit.find(params[:habit_id])
    end

    # Only allow a list of trusted parameters through.
    def habit_entry_params
      params.require(:habit_entry).permit(:date, :status)
    end
end
