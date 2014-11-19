# This provides a place for Pulp repository overrides. See README.md for more information.

class pulp::repo (
    $repo_name      = 'pulp-stable',
    $repo_descr     = 'Pulp Stable Repository',
    $repo_baseurl   = 'https://repos.fedorapeople.org/repos/pulp/pulp/stable/2',
    $repo_enabled   = 1,
    $repo_gpgcheck  = 0,
    $repo_priority  = 0
) {
    # Install the repository file
    case $::operatingsystem {
        'Fedora': {
            if is_integer($::operatingsystemrelease) and $::operatingsystemrelease >= 19 {

                yumrepo { $repo_name:
                    descr    => $repo_descr,
                    baseurl  => "${repo_baseurl}/fedora-${::operatingsystemrelease}/${::architecture}/",
                    enabled  => $repo_enabled,
                    gpgcheck => $repo_gpgcheck
                }

            } else {
                fail("${::operatingsystem} ${::operatingsystemrelease} is unsupported.")
            }
        }
        'RedHat', 'CentOS': {
            if versioncmp($::facterversion, 2.0) < 0 {
                package { 'redhat-lsb':
                    ensure => 'installed'
                }
                $release_version = $::lsbmajdistrelease
                Package['redhat-lsb'] -> Yumrepo[$repo_name]
            } else {
                $release_version = $::operatingsystemmajrelease
            }
            yumrepo { $repo_name:
                descr    => $repo_descr,
                baseurl  => "${repo_baseurl}/${release_version}Server/${::architecture}/",
                enabled  => $repo_enabled,
                gpgcheck => $repo_gpgcheck
            }
            # For compatibility with yum module
            if $repo_priority != 0 {
                Yumrepo[$repo_name] { priority => $repo_priority }
            }
        }
        default: {
            fail('Currently, this module only supports RedHat, CentOS and Fedora operating systems.')
        }
    }
}
