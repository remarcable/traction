class HabitEntriesController < ApplicationController
  before_action :set_habit
  before_action :set_habit_entry, only: %i[ show edit update destroy cycle_status ]

  # GET /habit_entries or /habit_entries.json
  def index
    @habit_entries = @habit.habit_entries
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
    # TODO: If entry for date already exists, silently update it?
    @habit_entry = @habit.habit_entries.build(habit_entry_params)
    if @habit_entry.save
      redirect_to @habit, notice: "Entry was successfully created."
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

  def cycle_status
    current_index = HabitEntry.statuses.keys.index(@habit_entry.status)
    next_index = (current_index + 1) % HabitEntry.statuses.keys.length
    next_status = HabitEntry.statuses.keys[next_index]

    @habit_entry.update(status: next_status)
    redirect_to request.referer
  end

  def create_and_cycle
    @habit_entry = @habit.habit_entries.build(
      date: params[:date],
      status: HabitEntry.statuses.keys[1]
    )

    if @habit_entry.save
      redirect_to request.referer
    else
      redirect_to request.referer, alert: "Could not create entry"
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_habit_entry
      @habit_entry = @habit.habit_entries.find(params[:id])
    end

    def set_habit
      @habit = Current.session.user.habits.find(params[:habit_id])
    end

    # Only allow a list of trusted parameters through.
    def habit_entry_params
      params.require(:habit_entry).permit(:date, :status)
    end
end
