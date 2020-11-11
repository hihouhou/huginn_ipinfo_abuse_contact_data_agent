require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::IpinfoAbuseContactDataAgent do
  before(:each) do
    @valid_options = Agents::IpinfoAbuseContactDataAgent.new.default_options
    @checker = Agents::IpinfoAbuseContactDataAgent.new(:name => "IpinfoAbuseContactDataAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
