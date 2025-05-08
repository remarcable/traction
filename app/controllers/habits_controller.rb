class HabitsController < ApplicationController
  before_action :set_habit, only: %i[ show edit update destroy ]

  # GET /habits or /habits.json
  def index
    @habits = Current.session.user.habits
  end

  # GET /habits/1 or /habits/1.json
  def show
    @habit = Current.session.user.habits.find(params[:id])
  end

  # GET /habits/new
  def new
    @habit = Habit.new
  end

  # GET /habits/1/edit
  def edit
  end

  # POST /habits or /habits.json
  def create
    @habit = Habit.new(habit_params)
    @habit.user = Current.session.user

    respond_to do |format|
      if @habit.save
        format.html { redirect_to @habit, notice: "Habit was successfully created." }
        format.json { render :show, status: :created, location: @habit }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @habit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /habits/1 or /habits/1.json
  def update
    respond_to do |format|
      if @habit.update(habit_params)
        format.html { redirect_to @habit, notice: "Habit was successfully updated." }
        format.json { render :show, status: :ok, location: @habit }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @habit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /habits/1 or /habits/1.json
  def destroy
    @habit.destroy!

    respond_to do |format|
      format.html { redirect_to habits_path, status: :see_other, notice: "Habit was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    def set_habit
      @habit = Current.session.user.habits.find(params[:id])
    end

    def habit_params
      params.require(:habit).permit(:name)
    end
end
