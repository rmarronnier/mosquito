require "../../test_helper"

describe "Mosquito::Runner logs" do
  let(:runner) { Mosquito::TestableRunner.new }
  getter backend : Mosquito::Backend { Mosquito.backend.named "test" }

  def register_mappings
    Mosquito::Base.register_job_mapping "queued_test_job", QueuedTestJob
    Mosquito::Base.register_job_mapping "failing_job", FailingJob
  end

  def run_task(job)
    job.new.enqueue

    runner.run :fetch_queues
    runner.run :run
  end

  describe "success/failures messages" do
    it "logs a success message when the job succeeds" do
      clean_slate do
        register_mappings

        clear_logs
        run_task QueuedTestJob
        assert_includes logs, "Success"
      end
    end

    it "logs a failure message when the job fails" do
      clean_slate do
        register_mappings
        clear_logs
        run_task FailingJob
        assert_includes logs, "Failure"
      end
    end
  end

  describe "job timing messages" do
    it "logs the time a job took to run" do
      clean_slate do
        register_mappings
        clear_logs
        run_task QueuedTestJob
        assert_includes logs, "and took"
      end
    end

    it "logs the time a job took to run when the job fails" do
      clean_slate do
        register_mappings
        clear_logs
        run_task FailingJob
        assert_includes logs, "taking"
      end
    end
  end

  describe "start and finish messages" do
    it "logs the job run start message" do
      clean_slate do
        register_mappings
        clear_logs
        run_task QueuedTestJob
        assert_includes logs, "Starting: queued_test_job"
      end
    end
  end

  describe "messages for finding ready delayed and scheduled jobs" do
    it "logs when it finds delayed tasks" do
      clean_slate do
        register_mappings
        clear_logs
        QueuedTestJob.new.enqueue at: 1.second.ago
        runner.run :fetch_queues
        runner.run :enqueue
        assert_includes logs, "Found 1 delayed task"
      end
    end
  end
end
