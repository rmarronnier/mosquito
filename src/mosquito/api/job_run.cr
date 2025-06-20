module Mosquito::Api
  # Represents a job run in Mosquito.
  #
  # This class is used to inspect a job run stored in the backend.
  #
  # For more information about a JobRun, see `Mosquito::JobRun`.
  class JobRun
    # The id of the job run.
    getter id : String

    def initialize(@id : String)
    end

    # Does a JobRun with this ID exist in the backend?
    def found? : Bool
      config.has_key? "type"
    end

    # Get the parameters the job was enqueued with.
    def runtime_parameters : Hash(String, String)
      config.reject do |key, _|
        ["id", "type", "enqueue_time", "retry_count", "started_at", "finished_at"].includes? key
      end
    end

    private def config : Hash(String, String)
      Mosquito.backend.retrieve config_key
    end

    private def config_key
      Mosquito.backend.build_key Mosquito::JobRun::CONFIG_KEY_PREFIX, id
    end

    # The type of job this job run is for.
    def type : String
      config["type"]
    end

    # The moment this job was enqueued.
    def enqueue_time : Time
      Time.unix_ms config["enqueue_time"].to_i64
    end

    # The moment this job was started.
    def started_at : Time?
      if time = config["started_at"]
        Time.unix_ms time.to_i64
      end
    end

    # The moment this job was finished.
    def finished_at : Time?
      if time = config["finished_at"]
        Time.unix_ms time.to_i64
      end
    end

    # The number of times this job has been retried.
    def retry_count : Int
      config["retry_count"].to_i
    end

    # The duration of the job run if it has finished.
    def duration : Time::Span?
      if (start_time = started_at) && (end_time = finished_at)
        end_time - start_time
      end
    end

    # The current state of the job run.
    def state : String
      if finished_at
        "finished"
      elsif started_at
        "running"
      else
        "queued"
      end
    end

    # Check if the job run was successful.
    def successful? : Bool
      !!finished_at && !dead?
    end

    # Check if the job run failed.
    def failed? : Bool
      dead?
    end

    # Check if the job run is in the dead queue.
    def dead? : Bool
      # Check if this job exists in any dead queue
      Mosquito.backend.list_queues.any? do |queue_name|
        backend = Mosquito.backend.named(queue_name)
        backend.dump_dead_q.includes?(id)
      end
    end

    # Get the queue this job belongs to.
    def queue_name : String?
      config["queue"]?
    end

    # JSON representation of the job run for API responses.
    def to_h
      {
        "id"                 => id,
        "type"               => type,
        "state"              => state,
        "queue_name"         => queue_name,
        "enqueue_time"       => enqueue_time,
        "started_at"         => started_at,
        "finished_at"        => finished_at,
        "duration"           => duration.try(&.total_milliseconds.to_i64),
        "retry_count"        => retry_count,
        "successful"         => successful?,
        "failed"             => failed?,
        "runtime_parameters" => runtime_parameters,
      }
    end
  end
end
