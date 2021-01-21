# my_app

This module can be used to manage my_app deployments.

It contains the Puppet code and data to configure the Puppet resources to manage during my_app update and deployment. It's supposed to be self-contained and to be used as a standalone module, in Puppet apply mode.
## Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with my_app](#setup)
    * [What my_app affects](#what-my_app-affects)
    * [Beginning with my_app](#beginning-with-my_app)
3. [Usage - Configuration options and additional functionality](#usage)


## Description

This module manages and configures all the resources related to my_app:

- [Eventual] packages to be installed via Puppet package resource
- [Eventual] services to be managed via Puppet service resource
- [Eventual] users to be managed via Puppet user resource
- Configuration files, managed by Puppet file resource

All these resources are declared in the main my_app class and in evental subclasses based on the Hiera data present in [this same module](data/), configured according to the Hierarchy defined in [hiera.yaml](hiera.yaml).

## Setup

Normal expected usage of this module is via a Puppet task which runs puppet apply of the class my_app after, eventually, having downloaded the contents of this module on the local node where is applied.

The script [apply/deploy.sh](apply/deploy.sh) is a shell wrapper around a **puppet task run** command to be executed from central control node which has access to Puppet Enterprise console API. The user running the script need to have a valid
 token created and not expired (as created via the **puppet access** command) with the permission to run the TASK 

### What my_app affects

This module manages different kind of Puppet resources according what's configured on Hiera.

The following Hiera keys can be used to managed Puppet resources related to my_app:

- **my_app::service**, to manage one or more services
- **my_app::package**, to manage one or more packages
- **my_app::user**, to manage one or more users
- **my_app::group**, to manage one or more groups
- **my_app::files**, to manage one or more files
- **my_app::resources**, an alternative, general purpose, entrypoint to manage any kind of Puppet resource

### Beginning with my_app

Just include my_app class to allow all the Hiera driven settings described below.

In apply mode, you can just apply the file [apply/apply.pp](apply/apply.pp).

This can be done from a central node with access to Puppet Enterprise Console API and a valid token, by running the script [apply/deploy.sh](apply/deploy.sh) passing as argument the node where to apply the code (and deploy my_app).

The file [apply/task_params.json](apply/task_params.json) contains the list of parameters passed to the task profile::puppet_apply.

## Usage

To configure what to do with this module you have to edit Hiera settings under [data](data) according to the Hierarchy you can  customise in  [hiera.yaml](hiera.yaml) where you can add any Hierarchy level which uses facts.

### Managing services

Services can be managed via a String, an Array or an Hash of services (with key-pairs matching the attributes of Puppet's [service type params](https://puppet.com/docs/puppet/latest/types/service.html)). For example, as a string:

    my_app::service: my_app

or, as an Array:

    my_app::service:
      - my_app
      - httpd

or, as a Hash:

    my_app::service:
      my_app:
        status: '/opt/my_app/bin/my_app status'
      httpd: {}

The default attributes added to each service type (or merged to the ones passed in the my_app::service Hash), can be configured as well. These are the default values:

    my_app::service_params:
      ensure: running
      enable: true

It's possible to automatically configure a service restart whenever a configuration file changes, as it happens by default:

    my_app::service_notify: true

### Managing packages

Similarly, packages can be managed via a String, an Array or an Hash of packages (with key-pairs matching the attributes of Puppet's [package type params](https://puppet.com/docs/puppet/latest/types/package.html)). As a String:

    my_app::package: my_app

as an Array:

    my_app::package:
      - my_app
      - my_app_prerequisite

or, as Hash:

    my_app::package:
      my_app:
        ensure: 1.0.1
      my_app_prerequisite:
        ensure: present


The default parameters added to each package (or merged to the ones present in the Hash of params) are:

    my_app::package_params:
      ensure: present

### Managing users and groups

Additional Users and groups can be automatically used as owners of the configuration files provided, and eventually created as Puppet Resource.

Users and groups can be defined exactly as packages and services, providing A String, and Array of an Hash of resources for the Hiera keys **my_app::user** and **my_app::group**.

If the value is a string the that user or group is used as owner of all the managed files, if it's an Array or and Hash, then the first element is used. Note howverwe that you can always override this by specifying different user and groups in the file resources.

To actually create users and groups via the relevant Puppet resources (by default they are not explicitly created):

    my_app::user_create: true
    my_app::group_create: true

To customise the attributes of Puppet's [user type params](https://puppet.com/docs/puppet/latest/types/user.html) (here are the default values):

    my_app::user_params:
      ensure: present

To customise the attributes of Puppet's [group type params](https://puppet.com/docs/puppet/latest/types/group.html) (here are the default values):

    my_app::group_params:
      ensure: present

### Managing configuration files

Any configuration file related to my_app can be configured via an Hash of Puppet file resources with the [relevant attributes](https://puppet.com/docs/puppet/latest/types/file.html): 

    my_app::files:
      /etc/my_app/my_app.conf:
        template: my_app/my_app.conf.erb
      /etc/my_app/auth.conf:
        epp: my_app/auth/auth.conf.epp
        mode: '0440'
      /etc/my_app/groups:
        content: 'admins: al,ma,sh'
        mode: '0640'
      /etc/my_app/keys:
        source: puppet:///modules/my_app/keys
        mode: '0400'

From the above example note that for better handling of the content of files, besides the normal attributes of the file resource (path, onwer, group, mode, content, source...) you can also specify the erb template to use with the **template** key, or the epp template with the **epp** key (writing something like: content: template(my_app/spaced.erb) would not work).

The above templates are expected, respectively, to be placed, in my_app module in the following paths:

  - templates/my_app.conf.erb
  - templates/auth/auth.conf.epp

the static file should be placed under:

  - files/keys

In the above templates it's possible to use the values of any key we may want to set via my_app::options Hiera key (which expects an Hash of key-pairs):

    my_app::options:
      listen: 8042
      servername: "my_app.%{::domain}" # This will be interpolated with the value of the domain fact
      allowed_ips:
        - 10.42.0.10
        - 192.168.0.10
      users:
        admin:
          token: f7e6fEywGqieuerhgdkcxghsaAz87cxtugE
        guest:
          token: fdfdskj876BBB98fdsfer32afesdf4gvdfs

The values of that hash can be used as follows. Example within an [erb template](https://puppet.com/docs/puppet/latest/lang_template_erb.html):

    # Configuration file for my_app
    listen: <%= @options['listen'] %>
    servername: <%= @options['servername'] %>
    allowed_ips:
      <% @options['allowed_ips'].each do |k| -%>
        - <%= k %>
      <% end -%>

The values of the options hash can be used in different files, for example $options['users'] key can bve used as follows

    users:
      <% @options['users'].each do |k,v| -%>
        <%= k %>:
          token <%= v['token'] %>
      <% end -%>

The above examples, within an [epp template](https://puppet.com/docs/puppet/latest/lang_template_epp.html) would look as follows:

    # Configuration file for my_app
    listen: <%= $my_app::options['listen'] %>
    servername: <%= $my_app::options['servername'] %>
    allowed_ips:
      <% $my_app::options['allowed_ips'].each |$k| {-%>
        - <%= $k %>
      <% } -%>

    users:
      <% $my_app::options['users'].each |$k,$v| { -%>
        <%= $k %>:
          token <%= $v['token'] %>
      <% } -%>

For common configuration files' structures, under the templates directory, there are some generic templates both in erp and epp format which can be used to iterate over all the keys specified under the **options** parameter:

- **inifile**. For configuration files in inifile format (key = value)
- **spaced**. For configuration files with spaced format (key value)
- **inifile_with_stanzas**. For configuration files in inifile format with stanzas (like smb.conf).
- **spaced_with_stanzas**. For configuration files in spaced format with stanzas.


The main differences between erb and epp templates are:

- erb templates embed Ruby code, epp templates embed Puppet code
- variables coming for the calling class are referred with @varname in erb and $varname in epp
- internal variables are referred with varname in erb and $varname in epp
- in epp class variables should be referred with the fully qualified names ($my_app::varname)
- facts can be referred with just their name in both cases. For example: @fqdn in erb and $fqdn in epp
- erb templates are passed to the Puppet template() function, epp templates are passed to the epp() function

###  Managing ANY Puppet resource

Besides the resources described above, it's possible, as an *alternative* or *complementary* approach, to define via Hiera data ANY kind of Puppet resource.

This is done by the **my_app::resources** key, which expects an Hash, whose first subkey is the name of the resource to manage which expects as value an Hash of resources of that type, with the relevant parameters.

To reduce data duplication, it's possible to specify, for each resource type, the default parameters with the **my_app::resources_defaults** keys.

Here's an example which creates exactly the same resources created in the above examples

    # The hash of resources to manage, for each resource type you can specify an hash of one or more resources with the relevant attributes.
    my_app::resources:
      service:
        my_app:
          status: '/opt/my_app/bin/my_app status'
        httpd: {}
      package:
        my_app:
          ensure: 1.0.1
        my_app_prerequisite:
          ensure: present
      user:
        my_app:
          ensure: present
      group:
        my_app:
          ensure: present
      file:
        /etc/my_app/my_app.conf:
          template: my_app/spaced.erb
        /etc/my_app/auth.conf:
          epp: my_app/auth/auth.conf.epp
          mode: '0440'
        /etc/my_app/groups:
          content: 'admins: al,ma,sh'
           mode: '0640'
        /etc/my_app/keys:
          source: puppet:///modules/my_app/keys
          mode: '0400'

From the above example note that for better handling of the content of files, besides the normal attributes of the file resource (path, onwer, group, mode, content, source...) you can also specify the erb template to use with the **template** key, or the epp template with the **epp** key (writing something like: content: template(my_app/spaced.erb) would not work).

    # The default values for the attributes for each resource type. If some of them are also set in the resources hash (like ensure: 1.0.1 for package my_app ), they have preferences over these defaults
    my_app::resources_defaults:
      service:
        ensure: running
        enable: true
      package:
        ensure: present

    # The options parameter can still be used and the relevant values used in templates.
    my_app::options:
      listen: 8042
      servername: "my_app.%{::domain}" # This will be interpolated with the value of the domain fact
      allowed_ips:
        - 10.42.0.10
        - 192.168.0.10
      users:
        admin:
          token: f7e6fEywGqieuerhgdkcxghsaAz87cxtugE
        guest:
          token: fdfdskj876BBB98fdsfer32afesdf4gvdfs

NOTE: The keys **my_app::resources** and **my_app::resources_defaults** have in configured in [data/common.yaml](data/common.yaml) to use 'deep' as lookup merge behaviour.

With this setting Hiera traverses all the files defined in hiera.yaml to look for they keys and returns an Hash with all the values found for them merged together (when the same subkeys are set, files at the top of the hierarchy have precedence).

Alternatively, if in [data/common.yaml](data/common.yaml) you change to 'first' the lookup_options for these keys then the relevant Hiera keys are looked up using the first method and Hiera returns the first value found for them.

More information on Hiera merge behaviours and how they can be configured in data in module:

- [Official Documentation](https://puppet.com/docs/puppet/5.5/hiera_merging.html)


## Testing the module locally

It's possible to test this module locally, without the need of running puppet apply via a task.

In order to do this, assuming the module is stored under /var/tmp/modules/, it's enough to run:

    puppet apply --modulepath=/var/tmp/modules/ /var/tmp/modules/my_app/apply/apply.pp

This command can be run as root or also as a normal user, just notice that if run as normal user it may fail to apply resources which need root permissions (like installing packages, managing services, creating files with root owner and so on).


## Creating a new module based on my_app

The script **module_rename.sh** is available to quickly create a new module based on my_app module.

In order to use it, run the following commands:

    cd $modulepath/my_app
    bash module_rename.sh my_app new_module_name

    cd ..
    mv my_app new_module_name

The **module_rename.sh** basically finds and replaces the my_app string with what you specify as new_module_name.


