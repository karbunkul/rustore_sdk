describe Fastlane::Actions::RustoreUploadAabAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The rustore_upload_aab action is working!")

      Fastlane::Actions::RustoreUploadAabAction.run(nil)
    end
  end
end
