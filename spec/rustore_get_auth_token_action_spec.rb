describe Fastlane::Actions::RustoreGetAuthTokenAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The rustore_get_auth_token action is working!")

      Fastlane::Actions::RustoreGetAuthTokenAction.run(nil)
    end
  end
end
