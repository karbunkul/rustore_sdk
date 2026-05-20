describe Fastlane::Actions::RustoreGetAppVersionAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The rustore_get_app_version action is working!")

      Fastlane::Actions::RustoreGetAppVersionAction.run(nil)
    end
  end
end
