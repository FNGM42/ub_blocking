# Preview all emails at http://localhost:3000/rails/mailers/ub_mailer
class UbMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/ub_mailer/new_block
  def new_block
    UbMailer.new_block
  end

end
