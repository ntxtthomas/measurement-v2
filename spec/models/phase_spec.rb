require "rails_helper"

RSpec.describe Phase, type: :model do
  describe "associations" do
    it { should have_many(:epics).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "#completion_percentage" do
    let(:phase) { create(:phase) }
    let(:epic)  { create(:epic, phase: phase) }
    let(:story) { create(:story, epic: epic) }

    it "returns 0 when there are no tasks" do
      expect(phase.completion_percentage).to eq(0)
    end

    it "returns 0 when all tasks are not_started" do
      3.times { create(:task, story: story, status: :not_started) }
      expect(phase.completion_percentage).to eq(0)
    end

    it "returns 100 when all tasks are done" do
      3.times { create(:task, story: story, status: :done) }
      expect(phase.completion_percentage).to eq(100)
    end

    it "returns 50 when half the tasks are done" do
      2.times { create(:task, story: story, status: :done) }
      2.times { create(:task, story: story, status: :not_started) }
      expect(phase.completion_percentage).to eq(50)
    end
  end

  describe "#status_label" do
    let(:phase) { create(:phase) }
    let(:epic)  { create(:epic, phase: phase) }
    let(:story) { create(:story, epic: epic) }

    it "returns 'Not Started' with no tasks" do
      expect(phase.status_label).to eq("Not Started")
    end

    it "returns 'In Progress' when partially complete" do
      create(:task, story: story, status: :done)
      create(:task, story: story, status: :not_started)
      expect(phase.status_label).to eq("In Progress")
    end

    it "returns 'Complete' when all tasks are done" do
      create(:task, story: story, status: :done)
      expect(phase.status_label).to eq("Complete")
    end
  end
end

RSpec.describe Task, type: :model do
  describe "associations" do
    it { should belong_to(:story) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "status enum" do
    it "is not_started by default" do
      task = build(:task)
      expect(task).to be_not_started
    end

    it "can be set to done" do
      task = create(:task, status: :done)
      expect(task).to be_done
    end

    it "can be set to blocked" do
      task = create(:task, status: :blocked)
      expect(task).to be_blocked
    end
  end
end
