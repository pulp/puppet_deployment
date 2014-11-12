require 'spec_helper'

describe 'pulp::server' do

  context 'on redhat' do
    let :facts do
      {
        :concat_basedir             => '/tmp',
        :operatingsystem            => 'RedHat',
        :operatingsystemrelease     => '6.4',
        :operatingsystemmajrelease  => '6',
        :osfamily                   => 'RedHat',
      }
    end

    it { should contain_class('pulp::globals') }
    it { should contain_class('pulp::server::install').that_comes_before('pulp::server::config') }
    it { should contain_class('pulp::server::config') }
    it { should contain_class('pulp::server::service').that_subscribes_to('pulp::server::config') }

    it { should contain_service('pulp_workers') }
  end

  context 'on redhat 5' do
    let :facts do
      {
        :concat_basedir             => '/tmp',
        :operatingsystem            => 'RedHat',
        :operatingsystemrelease     => '5.2',
        :operatingsystemmajrelease  => '5',
        :osfamily                   => 'RedHat',
      }
    end

    it { expect { should contain_class('pulp::server') }.to raise_error(Puppet::Error, /Pulp servers are not supported on RHEL5/) }
  end

end
