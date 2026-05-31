ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
Dir[Rails.root.join("test/support/**/*.rb")].each { |f| require f }

# Minitest 6 removed Object#stub; provide a compatible helper for class/module stubs.
module MochaClassStub
  def stub(method_name, val_or_callable, &block)
    expectation = stubs(method_name)
    if val_or_callable.is_a?(Proc)
      expectation.returns { |*args, **kwargs, &callable|
        val_or_callable.arity.zero? ? val_or_callable.call : val_or_callable.call(*args, **kwargs, &callable)
      }
    else
      expectation.returns(val_or_callable)
    end
    yield
  ensure
    unstub(method_name)
  end
end

Module.prepend(MochaClassStub)

Warden.test_mode!

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include OnboardingTestHelper
  include TestTaxIds

  setup do
    owner = users(:owner) rescue nil
    sign_in owner if owner
  end
end

module ActiveSupport
  class TestCase
    include OnboardingTestHelper
    include PermissionTestHelper
    include TestTaxIds
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    setup do
      seed_account_permissions!
    end

    # Add more helper methods to be used by all tests here...
  end
end
