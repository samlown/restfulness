require 'spec_helper'

describe Restfulness::Sanitizer do
  describe 'Hash' do
    it 'does nothing when not given any sensitive params' do
      subject = described_class::Hash.new()
      input = {:password => 'ok', :nested => {:password => 'okay'}}
      subject.sanitize(input).should eq input
    end

    it 'filters sensitive param and not others' do
      subject = described_class::Hash.new(:password)
      input = {:PASSword => 'supersecret', :user => 'billy'}
      subject.sanitize(input).should eq({:PASSword => described_class::SANITIZED, :user => 'billy'})
    end

    it 'filters nested sensitive params and not others' do
      subject = described_class::Hash.new(:password)
      input = {:user => {:passWORD => 'supersecret', :user => 'billy'}}
      subject.sanitize(input).should eq({:user => {:passWORD => described_class::SANITIZED, :user => 'billy'}})
    end

    it 'filters any parameter beginning with sensitive params (prefix)' do
      subject = described_class::Hash.new(:password)
      input = {:user => {:passWORD_confirmation => 'supersecret', :user => 'billy'}}
      subject.sanitize(input).should eq({:user => {:passWORD_confirmation => described_class::SANITIZED, :user => 'billy'}})
    end
  end

  describe 'QueryString' do
    it 'does nothing when not given any sensitive params' do
      subject = described_class::QueryString.new()
      input = 'password=ok&other=false'
      subject.sanitize(input).should eq input
    end

    it 'filters sensitive param and not others' do
      subject = described_class::QueryString.new(:password)
      input = 'PASSword=ok&other=false'
      subject.sanitize(input).should eq "PASSword=#{described_class::SANITIZED}&other=false"
    end

    it 'filters nested (with index) sensitive params and not others' do
      subject = described_class::QueryString.new(:password)
      input = 'password[0]=what&PASSword[1]=secret&other=false'
      subject.sanitize(input).should eq "password[0]=#{described_class::SANITIZED}&PASSword[1]=#{described_class::SANITIZED}&other=false"
    end

    it 'filters nested (no index) sensitive params and not others' do
      subject = described_class::QueryString.new(:password)
      input = 'password[]=what&password[]=secret&other=false'
      subject.sanitize(input).should eq "password[]=#{described_class::SANITIZED}&password[]=#{described_class::SANITIZED}&other=false"
    end

    it 'filters any parameter beginning with sensitive params (prefix)' do
      subject = described_class::QueryString.new(:password)
      input = 'password_confirmation[]=what&password[]=secret&password=false'
      subject.sanitize(input).should eq "password_confirmation[]=#{described_class::SANITIZED}&password[]=#{described_class::SANITIZED}&password=#{described_class::SANITIZED}"
    end
  end
end
