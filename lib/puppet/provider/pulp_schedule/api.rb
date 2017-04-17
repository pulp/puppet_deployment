#  Limitations:
# - we can't have multiple schedules for the same repo, so we force the existence of only one schedule per repo 
#   (the one with the smallest sync_id). The resource name will be the repo_id
# - user should not set the name of a repo to be the same as an existing schedule_id (probability is very small)
# - if the repo (resource name) doesn't exists, the resource will fail (normal)
# - there is a global variable used ($schedules_info)
#
# Explanation on how it's implemented:
# - when we get the resources, we set the resource name to repo_id only for the first schedule
# - the other schedules get the name = schedule_id (this is useful only for purging)
# - we need to keep somewhere the schedule_id for the first ones ($schedules_info['schedule_id']): this is needed in update
# - we need to keep the repo_id for the second ones ($schedules_info['repo_id']): needed in delete, when we purge the resources
# - since this provider is global for all repos, we need to keep the repo_type for all repos ($schedules_info['repo_type'])
# - a special case is when we have a single resource defined in puppet with ensure => absent: we keep the schedule id in $schedules_info['repo_id']

require File.expand_path('../../../util/pulp_util', __FILE__)

Puppet::Type.type(:pulp_schedule).provide(:api) do
  commands :pulp_admin => '/usr/bin/pulp-admin'

  mk_resource_methods
  $schedules_info ||= Hash.new
  $schedules_info['repo_id'] ||= Hash.new
  $schedules_info['schedule_id'] ||= Hash.new
  $schedules_info['repo_type'] ||= Hash.new

  def initialize(resource={})
    super(resource)
    @property_flush = {}
  end

  def self.get_resource_properties(repo_id)
    all = []
    sync_id = nil
    # get_repo_syncs return an array with all schedules and the repo type
    schedules =  @pulp.get_repo_syncs(repo_id)
    all_schedules = schedules[0]
    $schedules_info['repo_type'][repo_id] = schedules[1]

    # first get the lowest sync id
    all_schedules.each { |schedule|
      if sync_id && sync_id < schedule['_id']
        sync_id = schedule['_id']
      elsif !sync_id
        sync_id = schedule['_id']
      end
    }

    # create resources
    all_schedules.each { |schedule|
      hash = {}
      hash[:ensure] = :present
      hash[:provider] = :pulp_schedule

      # in case where we are the previously saved sync_id, we set this as the _main_ resource
      if sync_id == schedule['_id']
        hash[:name] = repo_id
        $schedules_info['repo_id'][repo_id] = schedule['_id']
      else
        # otherwise we create a dummy resource that can be purged if not needed
        hash[:name] = schedule['_id']
        $schedules_info['schedule_id'][schedule['_id']] = repo_id
      end

      hash[:schedule_time] = schedule['schedule']
      hash[:enabled] = schedule['enabled'] == true ? :true : :false
      hash[:failure_threshold] = schedule['failure_threshold']
      all << new(hash)
    }
    all
  end

  def self.instances
    all = []

    @pulp = Puppet::Util::PulpUtil.new
    @pulp.get_repos.each { |repo|
      all << get_resource_properties(repo['id'])
    }
    all.flatten
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @property_flush[:ensure] = :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  # iterates through the array of resources returned by self.instances
  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    set_schedule

    # Some of the resources have now schedule_id as the name, so we try to fix this
    if $schedules_info['repo_id'].has_key?(resource[:name])
      repo_id = resource[:name]
    else
      repo_id = $schedules_info['schedule_id'][resource[:name]]
    end

    # Collect the resources again once they've been changed (that way `puppet
    # resource` will show the correct values after changes have been made).
    @property_hash = self.class.get_resource_properties(repo_id)
  end

  def set_schedule
    params = []
    params << ['--schedule', resource[:schedule_time]]
    params << ['--failure-threshold', resource[:failure_threshold]] if resource[:failure_threshold]
    repo_id = resource[:name]

    if @property_flush[:ensure] == :absent
      # delete
      action = 'delete'
      if $schedules_info['repo_id'].has_key?(resource[:name])
        # this is a _main_ resource
        params = ['--schedule-id', $schedules_info['repo_id'][resource[:name]]]
      else
        # this is one of the dummy resources
        repo_id = $schedules_info['schedule_id'][resource[:name]]
        params = ['--schedule-id', resource[:name]]
      end
    elsif @property_flush[:ensure] == :present
      # create
      action = 'create'
      # because create doesn't reach get_resource_properties, set repo type and id here also
      @pulp = Puppet::Util::PulpUtil.new
      schedules =  @pulp.get_repo_syncs(resource[:name])
      $schedules_info['repo_type'][resource[:name]] = schedules[1]
      $schedules_info['repo_id'][resource[:name]] = resource[:name]
    else
      # update
      params << ['--schedule-id', $schedules_info['repo_id'][resource[:name]]]
      params << ['--enabled', resource[:enabled]] if !resource[:enabled].nil?
      action = 'update'
    end

    case $schedules_info['repo_type'][repo_id]
    when 'rpm-repo'
      type = 'rpm'
    when 'puppet-repo'
      type = 'puppet'
    else
      raise "Unknown repo type #{$schedules_info['repo_type'][repo_id]} for repo_id #{repo_id}"
    end

    arr = [type, 'repo', 'sync', 'schedules', action, '--repo-id', repo_id, params]
    pulp_admin(arr.flatten)
  end

end
