require 'test_helper'

class UbMailerTest < ActionMailer::TestCase
  test "new_block" do
    mail = UbMailer.new_block
    assert_equal "New block", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
