# @summary This class can be used to configure and deploy my_app
#
# Class can be used both in Puppet agent and apply mode.
# Directory apply contains necessary manifests and scripts.
# Directory tasks contains a task to deploy the application.
#
# @param resources An hash of an Hash of any Puppet resource type to apply.
#   Consider it as a catch all way to set on Hiera any resource of any type.
#   You can always specify for each resource type the default parameters via
#   the my_app::resources_defaults Hiera key.
#   See below for a sample usage. 
#   This is not actually a class parameter, but a Hiera key looked up using the
#   merge behaviour configured via $resources_merge_behaviour
# @param resources_merge_behaviour Defines the lookup method to use to
#   retrieve via hiera the my_app::resources key
# @param resources_defaults An Hash of resources with an Hash of default
#   parameters to apply to the relevant resources.
#   This is not actually a class parameter, but a key looked up using the
#   merge behaviour configured via $resources_defaults_merge_behaviour
# @param resources_defaults_merge_behaviour Defines the lookup method to use to
#   retrieve via hiera the my_app::resources_defaults key
#
# @example Define arbitrary resources, with some defaults
#     my_app::resources:
#       file:
#         /usr/local/bin/eyaml:
#           target: /opt/puppetlabs/puppet/bin/eyaml
#       package:
#         zsh: {}
#         ksh: {}
#         nrpe:
#           ensure: absent
#       my_app::users::managed:
#         test:
#           ensure: present
#     my_app::resources_defaults:
#       package:
#         ensure: present
#       my_app::users::managed:
#         shell: /bin/bash
class my_app (
  # General resources related to my_app deployment

  Variant[Undef,String,Array,Hash] $service = undef,
  Hash $service_params                      = { },
  Boolean $service_notify                   = true,

  Variant[Undef,String,Array,Hash] $package = undef,
  Hash $package_params                      = { },

  Variant[Undef,String] $user  = undef,
  Boolean $user_create         = false,
  Hash $user_params            = { },

  # Hash $resources (lookup with $resources_merge_behaviour)                   = {},
  # Hash $resources_defaults (lookup with $resources_defaults_merge_behaviour) = {},
  Enum['first','hash','deep'] $resources_merge_behaviour          = 'deep',
  Enum['first','hash','deep'] $resources_defaults_merge_behaviour = 'deep',
) {

  case $service {
    String: {
      service { $service:
        * => $service_params,
      }
    }
    Array: {
      $service.each | $s | {
        service { $s:
          * => $service_params,
        }
      }
    }
    Hash: {
      $service.each | $s,$p | {
        service { $s:
          * => $service_params + $p,
        }
      }
    }
    default: {}
  }

  case $package {
    String: {
      package { $package:
        * => $package_params,
      }
    }
    Array: {
      $package.each | $s | {
        package { $s:
          * => $package_params,
        }
      }
    }
    Hash: {
      $package.each | $s,$p | {
        package { $s:
          * => $package_params + $p,
        }
      }
    }
    default: {}
  }

  if $service_notify {
    File {
      notify => Service[$service],
    }
  }

  # General resources configured via Hiera
  $resources = lookup('my_app::resources',Hash,$resources_merge_behaviour,{})
  $resources_defaults = lookup('my_app::resources_defaults',Hash,$resources_defaults_merge_behaviour,{})

  $resources.each |$k,$v| {
    if $k in keys($resources_defaults) {
      $resource_defaults = $resources_defaults[$k]
    } else {
      $resource_defaults = {}
    }
    create_resources( $k, $v, $resource_defaults )
  }

}
