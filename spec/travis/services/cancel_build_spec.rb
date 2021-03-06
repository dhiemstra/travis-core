require 'spec_helper'

describe Travis::Services::CancelBuild do
  include Support::ActiveRecord

  let(:repo)    { Factory(:repository) }
  let!(:job)    { Factory(:test, repository: repo, state: :created) }
  let!(:passed_job) { Factory(:test, repository: repo, state: :passed) }
  let(:build)   { Factory(:build, repository: repo) }
  let(:params)  { { id: build.id } }
  let(:user)    { Factory(:user) }
  let(:service) { described_class.new(user, params) }

  before do
    build.matrix.destroy_all
    build.matrix << passed_job
    build.matrix << job
  end

  describe 'run' do
    it 'should cancel the build if it\'s cancelable' do
      job.stubs(:cancelable?).returns(true)
      service.stubs(:authorized?).returns(true)

      expect {
        expect {
          service.run
        }.to change { build.reload.state }
      }.to change { job.reload.state }

      job.state.should == 'canceled'
      build.state.should == 'canceled'
    end

    it 'should not cancel the job if it\'s not cancelable' do
      job.stubs(:cancelable?).returns(false)

      expect {
        service.run
      }.to_not change { build.reload.state }
    end

    it 'should not be able to cancel job if user does not have push permission' do
      user.permissions.create(repository_id: repo.id, push: false)

      service.can_cancel?.should be_false
    end
  end
end

