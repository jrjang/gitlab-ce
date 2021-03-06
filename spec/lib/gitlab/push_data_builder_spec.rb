require 'spec_helper'

describe Gitlab::PushDataBuilder, lib: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }


  describe '.build_sample' do
    let(:data) { described_class.build_sample(project, user) }

    it { expect(data).to be_a(Hash) }
    it { expect(data[:before]).to eq('6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }
    it { expect(data[:after]).to eq('5937ac0a7beb003549fc5fd26fc247adbce4a52e') }
    it { expect(data[:ref]).to eq('refs/heads/master') }
    it { expect(data[:commits].size).to eq(3) }
    it { expect(data[:total_commits_count]).to eq(3) }
    it { expect(data[:commits].first[:added]).to eq(["gitlab-grack"]) }
    it { expect(data[:commits].first[:modified]).to eq([".gitmodules"]) }
    it { expect(data[:commits].first[:removed]).to eq([]) }

    include_examples 'project hook data'
    include_examples 'deprecated repository hook data'
  end

  describe '.build' do
    let(:data) do
      described_class.build(project, user, Gitlab::Git::BLANK_SHA,
                            '8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b',
                            'refs/tags/v1.1.0')
    end

    it { expect(data).to be_a(Hash) }
    it { expect(data[:before]).to eq(Gitlab::Git::BLANK_SHA) }
    it { expect(data[:checkout_sha]).to eq('5937ac0a7beb003549fc5fd26fc247adbce4a52e') }
    it { expect(data[:after]).to eq('8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b') }
    it { expect(data[:ref]).to eq('refs/tags/v1.1.0') }
    it { expect(data[:commits]).to be_empty }
    it { expect(data[:total_commits_count]).to be_zero }

    it 'does not raise an error when given nil commits' do
      expect { described_class.build(spy, spy, spy, spy, spy, nil) }.
        not_to raise_error
    end
  end
end
