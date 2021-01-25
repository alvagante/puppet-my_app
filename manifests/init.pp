# @summary This class can be used to configure and deploy my_app
#
# Class can be used both in Puppet agent and apply mode.
# Directory apply contains necessary manifests and scripts.
# Directory tasks contains a task to deploy the application.
#
# @param service Optional service(s) to manage (value can be a String,
#   an Array or an Hash of service resources.
# @param service_params Parameters to add to the service resource(s).
#   If $service is an hash, this is merged with the hash values for each
#   service. Default is to start a service at boot time and ensure is running.
# @param service_notify When true service is restarted whenever a file
#   is changed.
# @param package Optional package(s) to manage (value can be a String,
#   an Array or an Hash of package resources.
# @param package_params Parameters to add to the package resource(s).
#   If $package is an hash, this is merged with the hash values for each
#   package. Default is to ensure the package is present.
# @param user Optional user(s) related to my_app. If set, all files set in $files
#   by default will be owned by this user. Value can be a String,
#   an Array or an Hash of user resources. If more than one user is provided, the
#   first one is used for files permission (override this with $file_params).
# @param user_create. If to create the above $user. If $user is set, $files are
#   managed and $user_create is false, then $user must exist on the system.
# @param user_params Parameters to add to the user resource.
# @param group Optional group related to my_app. If set, all files set in $files
#   by default will be owned by this group. Value can be a String,
#   an Array or an Hash of group resources. If more than one group is provided, the
#   first one is used for files permission (override this with $file_params).
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
#   This key is looked up in deep merge behaviour, are configued in data/common.yaml
# @param resources_defaults An Hash of resources with an Hash of default
#   parameters to apply to the relevant resources.
#   This key is looked up in deep merge behaviour, are configued in data/common.yaml
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

  Variant[Undef,String,Array,Hash] $user  = undef,
  Boolean $user_create         = false,
  Hash $user_params            = { },

  Variant[Undef,String,Array,Hash] $group = undef,
  Boolean $group_create        = false,
  Hash $group_params           = { },

  Hash $files                  = { },
  Hash $options                = { },

  Hash $resources              = { },
  Hash $resources_defaults     = { },

) {

  # Manage service
  case $service {
    String: {
      service { $service:
        * => $service_params,
      }
      $file_notify = Service[$service]
    }
    Array: {
      $service.each | $s | {
        service { $s:
          * => $service_params,
        }
      }
      $file_notify = Service[$service]
    }
    Hash: {
      $service.each | $s,$p | {
        service { $s:
          * => $service_params + $p,
        }
      }
      $file_notify = Service[keys($service)]
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



  # Manage user
  case $user {
    String: {
      $file_user = $user
      if $user_create {
        user { $user:
          * => $user_params,
        }
      }
    }
    Array: {
      $file_user = $user[0]
      if $user_create {
        $user.each | $s | {
          user { $s:
            * => $user_params,
          }
        }
      }
    }
    Hash: {
      $file_user = keys($user)[0]
      if $user_create {
        $user.each | $s,$p | {
          user { $s:
            * => $user_params + $p,
          }
        }
      }
    }
    default: {}
  }

  # Manage group
  case $group {
    String: {
      $file_group = $group
      if $group_create {
        group { $group:
          * => $group_params,
        }
      }
    }
    Array: {
      $file_group = $group[0]
      if $group_create {
        $group.each | $s | {
          group { $s:
            * => $group_params,
          }
        }
      }
    }
    Hash: {
      $file_group = keys($group)[0]
      if $group_create {
        $group.each | $s,$p | {
          group { $s:
            * => $group_params + $p,
          }
        }
      }
    }
    default: {}
  }

  # Manage files
  if $service_notify and $service {
    File {
      notify => $file_notify,
      owner  => $file_user,
      group  => $file_group,
    }
  }

  $files.each | $k,$v | {
    if 'template' in keys($v) {
      $template_ext=$v['template'][-4,4]
      case $template_ext {
        '.epp': {
          $content_param = {
            content => epp($v['template']),
          }
        }
        '.erb': {
          $content_param = {
            content => template($v['template']),
          }
        }
        default: {
          fail("Template parameter in ${files} MUST contain a string with .erb or .epp suffix")
        }
      }
    } else {
      $content_param = {}
    }

    file { $k:
      * => $content_param + $v - ['template'],
    }
  }

  # Manage extra resources
  $resources.each | $k,$v | {
    if $k in keys($resources_defaults) {
      $resource_defaults = $resources_defaults[$k]
    } else {
      $resource_defaults = {}
    }
    create_resources( $k, $v, $resource_defaults )
  }

}
