require 'spec_helper'

describe 'pulp' do

 context 'on redhat' do
    let :facts do
      {
        :concat_basedir             => '/tmp',
        :operatingsystem            => 'RedHat',
        :operatingsystemrelease     => '6.4',
        :operatingsystemmajrelease  => '6.4',
        :osfamily                   => 'RedHat',
      }
    end

    it { expect { should contain_class('pulp') }.to raise_error(Puppet::Error, /Please use pulp::server, pulp::node, or pulp::consumer/) }
  end

end
