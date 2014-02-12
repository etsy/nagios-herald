class MockEmailMessage < NagiosHerald::EmailMessage
  attr_reader :sent

  def initialize(recipients, options = {})
    super(recipients, options)
    @sent = false
  end

  def send
    @sent = true
  end
end