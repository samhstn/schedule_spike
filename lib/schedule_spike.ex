defmodule ScheduleSpike do
  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    schedule_work() # Schedule work to be performed at some point
    {:ok, state}
  end

  def handle_info({:work, ms}, state) do
    Logger.info("Work after #{ms}ms")
    schedule_work() # Reschedule once more
    {:noreply, state}
  end

  defp schedule_work() do
    five_seconds = 5 * 1000
    Process.send_after(self(), {:work, five_seconds}, five_seconds)
  end
end
