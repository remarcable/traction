class HabitEntriesController < ApplicationController
  before_action :set_habit
  before_action :set_habit_entry, only: %i[ cycle_status ]

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
