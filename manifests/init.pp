# @summary This class can be used to configure and deploy my_app
#
# Class can be used both in Puppet agent and apply mode.
# Directory apply contains necessary manifests and scripts.
# Directory tasks contains a task to deploy the application.
#
# @param service Optional service(s) to manage (value can be a String,
#   and Array or an Hash of service resources.
# @param service_params Parameters to add to the service resource(s).
#   If $service is an hash, this is merged with the hash values for each
#   service. Default is to start a service at boot time and ensure is running.
# @param service_notify When true service is restarted whenever a file
#   is changed.
# @param package Optional package(s) to manage (value can be a String,
#   and Array or an Hash of package resources.
# @param package_params Parameters to add to the package resource(s).
#   If $package is an hash, this is merged with the hash values for each
#   package. Default is to ensure the package is present.
# @param user Optional user related to my_app. If set, all files set in $files
#   by default will be owned by this user.
# @param user_create. If to create the above $user. If $user is set, $files are
#   managed and $user_create is false, then $user must exist on the system.
# @param user_params Parameters to add to the user resource.
# @param group Optional group related to my_app. If set, all files set in $files
#   by default will be owned by this group.
# @param group_create. If to create the above $group. If $group is set, $files are
#   managed and $group_create is false, then $group must exist on the system.
# @param group_params Parameters to add to the group resource.
# @param files An hash of Puppet file resources to manage. This files will
#   automatically notify $service, if $service_notify is true and will be owned
#   by $user and $group, if they are set.
# @param options An hash of custom options to use in templates specified in the
#   $files or $resources params. Use this to customize different settings that
#   you may want to set, via Hiera, for the same files on different nodes.
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
# @example Set custom files with relevant options, and manage my_app service
#   as String and package as Hash, with package version to install.
#     my_app::service: my_app
#     my_app::package:
#       my_app:
#         ensure: v2.0.1
#     my_app::files:
#       /etc/my_app/my_app.conf:
#         content: template('my_app/my_app.conf')
#       /etc/my_app/users:
#         content: template('my_app/users')
#         mode: 0400
#     my_app::options:
#       db_host: db.example.com
#       db_database: my_app-prod
#       db_user: my_app-prod
#       db_password: s3cr3t # Consider using eyaml or other to encrypt secrets
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

  Variant[Undef,String] $group = undef,
  Boolean $group_create        = false,
  Hash $group_params           = { },

  Hash $files                  = { },
  Hash $options                = { },

  # Hash $resources (lookup with $resources_merge_behaviour)                   = {},
  # Hash $resources_defaults (lookup with $resources_defaults_merge_behaviour) = {},
  Enum['first','hash','deep'] $resources_merge_behaviour          = 'deep',
  Enum['first','hash','deep'] $resources_defaults_merge_behaviour = 'deep',
) {

  # Manage service
  case $service {
    String: {
      service { $service:
        * => $service_params,
      }
      $file_notify = $service
    }
    Array: {
      $service.each | $s | {
        service { $s:
          * => $service_params,
        }
      }
      $file_notify = $service
    }
    Hash: {
      $service.each | $s,$p | {
        service { $s:
          * => $service_params + $p,
        }
      }
      $file_notify = keys($service)
    }
    default: {}
  }

  # Manage package
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

  # Manage files
  if $service_notify and $service {
    File {
      notify => $file_notify,
      owner  => $user,
      group  => $group,
    }
  }

  $files.each | $k,$v | {
    file { $k:
      * => $v,
    }
  }

  # Manage generic resources
  $resources = lookup('my_app::resources',Hash,$resources_merge_behaviour,{})
  $resources_defaults = lookup('my_app::resources_defaults',Hash,$resources_defaults_merge_behaviour,{})

  $resources.each | $k,$v | {
    if $k in keys($resources_defaults) {
      $resource_defaults = $resources_defaults[$k]
    } else {
      $resource_defaults = {}
    }
    create_resources( $k, $v, $resource_defaults )
  }

}
