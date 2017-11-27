class UbMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.ub_mailer.new_block.subject
  #
  def new_block
    @greeting = "Hi"

    mail to: "to@example.org"
  end
end
